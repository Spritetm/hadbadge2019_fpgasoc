
#include "tusb_option.h"
#include "device/dcd.h"
#include "dcd_tntusb_hw.h"

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

#include "gloss/mach_interrupt.h"

//#define DEBUG 1

#if DEBUG
#include "hexdump.h"
#define DEBUGMSG(...) do { printf("USB: "); printf(__VA_ARGS__); } while(0)
#define USB_CHECK(x) do { if (!(x)) printf("USB: check fail: " #x " (%s:%d)\n", __FILE__, __LINE__); } while (0)
#define DEBUGHEXDUMP(a, b) hexdump(a, b)
#else
#define DEBUGMSG(...)
#define USB_CHECK(x)
#define DEBUGHEXDUMP(a, b)
#endif

typedef struct {
	int mps;
	int xfer_len;
	int xfer_pos;
	int cur_plen;
	uint8_t *buffer;
} g_tnt_ep_in_t;

typedef struct {
	int mps;
	int xfer_len;
	int xfer_pos;
	uint8_t *buffer;
} g_tnt_ep_out_t;

typedef struct {
	g_tnt_ep_in_t in;
	g_tnt_ep_out_t out;
} g_tnt_ep_t;

typedef struct {
	int mem_free_ptr_in;
	int mem_free_ptr_out;
	g_tnt_ep_t ep[16];
	bool ep0_stall;
} g_tntusb_t;

static g_tntusb_t g_usb;


static void _usb_data_write(unsigned int dst_ofs, const void *src, int len) {
	/* FIXME unaligned ofs */
	const uint32_t *src_u32 = src;
	volatile uint32_t *dst_u32 = (volatile uint32_t *)((USB_DATA_BASE_TX) + dst_ofs);

	len = (len + 3) >> 2;
	while (len--)
		*dst_u32++ = *src_u32++;
}

static void _usb_data_read (void *dst, unsigned int src_ofs, int len) {
	/* FIXME unaligned ofs */
	volatile uint32_t *src_u32 = (volatile uint32_t *)((USB_DATA_BASE_RX) + src_ofs);
	uint32_t *dst_u32 = dst;
	DEBUGMSG("%p -> %p\n", src_u32, dst_u32);

	int i = len >> 2;

	while (i--)
		*dst_u32++ = *src_u32++;

	if ((len &= 3) != 0) {
		uint32_t x = *src_u32;
		uint8_t  *dst_u8 = (uint8_t *)dst_u32;
		while (len--) {
			*dst_u8++ = x & 0xff;
			x >>= 8;
		}
	}
}


static void _usb_hw_reset_ep(volatile struct tntusb_ep *ep) {
	ep->status = 0;
	ep->bd[0].csr = 0;
	ep->bd[0].ptr = 0;
	ep->bd[1].csr = 0;
	ep->bd[1].ptr = 0;
}

static void _usb_hw_reset(bool pu) {
	/* Clear all descriptors */
	for (int i=0; i<16; i++) {
		_usb_hw_reset_ep(&tntusb_ep_regs[i].out);
		_usb_hw_reset_ep(&tntusb_ep_regs[i].in);
		memset(&g_usb.ep, 0, sizeof(g_usb.ep));
	}

	/* Main control */
	tntusb_regs->csr = (pu ? TNTUSB_CSR_PU_ENA : 0) | TNTUSB_CSR_CEL_ENA | TNTUSB_CSR_ADDR_MATCH | TNTUSB_CSR_ADDR(0);
	tntusb_regs->ar  = TNTUSB_AR_BUS_RST_CLEAR | TNTUSB_AR_SOF_CLEAR | TNTUSB_AR_CEL_RELEASE;
}


/*------------------------------------------------------------------*/
/* Controller API
 *------------------------------------------------------------------*/

void usb_poll(void);

static mach_int_frame_t* usb_int_handler(mach_int_frame_t *frame) {
	usb_poll();
	return frame;
}

void dcd_init (uint8_t rhport) {
	DEBUGMSG("dcd_init()\n");
	(void) rhport;
	/* Main state reset */
	memset(&g_usb, 0x00, sizeof(g_usb));

	/* Reset and enable the core */
	_usb_hw_reset(true);

	/* Set interrupt handler */
	mach_set_int_handler(INT_NO_USB, usb_int_handler);
}

void dcd_int_enable(uint8_t rhport) {
	(void) rhport;
	mach_int_ena(1<<INT_NO_USB);
}

void dcd_int_disable(uint8_t rhport) {
	(void) rhport;
	mach_int_dis(1<<INT_NO_USB);
}

void dcd_set_address (uint8_t rhport, uint8_t dev_addr) {
	DEBUGMSG("dcd_set_address %d\n", dev_addr);
	// Response with status first before changing device address
	dcd_edpt_xfer(rhport, tu_edpt_addr(0, TUSB_DIR_IN), NULL, 0);
	
	//wait till sent
	while ((tntusb_ep_regs[0].in.bd[0].csr & TNTUSB_BD_STATE_MSK) != TNTUSB_BD_STATE_DONE_OK) ;
	tntusb_ep_regs[0].in.bd[0].csr=0;
	//set address
	tntusb_regs->csr = TNTUSB_CSR_PU_ENA | TNTUSB_CSR_CEL_ENA | TNTUSB_CSR_ADDR_MATCH | TNTUSB_CSR_ADDR(dev_addr);
	DEBUGMSG("Address set\n");
}

void dcd_set_config (uint8_t rhport, uint8_t config_num)
{
	DEBUGMSG("dcd_set_config\n");
	(void) rhport;
	(void) config_num;
	// Nothing to do
}

void dcd_remote_wakeup(uint8_t rhport)
{
	(void) rhport;
	//not implemented
}

/*------------------------------------------------------------------*/
/* DCD Endpoint port
 *------------------------------------------------------------------*/

bool dcd_edpt_open (uint8_t rhport, tusb_desc_endpoint_t const * desc_edpt) {
	(void) rhport;
	uint8_t const dir   = tu_edpt_dir(desc_edpt->bEndpointAddress);
	uint8_t const epnum = tu_edpt_number(desc_edpt->bEndpointAddress);

	int type=0;
	if (desc_edpt->bmAttributes.xfer==TUSB_XFER_CONTROL) type=TNTUSB_EP_TYPE_CTRL;
	if (desc_edpt->bmAttributes.xfer==TUSB_XFER_ISOCHRONOUS) type=TNTUSB_EP_TYPE_ISOC;
	if (desc_edpt->bmAttributes.xfer==TUSB_XFER_BULK) type=TNTUSB_EP_TYPE_BULK;
	if (desc_edpt->bmAttributes.xfer==TUSB_XFER_INTERRUPT) type=TNTUSB_EP_TYPE_INT;

	if (type == TNTUSB_EP_TYPE_CTRL) {
		DEBUGMSG("Setting up control endpoint %d, ptr_start = 0x%X/0x%X\n", epnum, g_usb.mem_free_ptr_in, g_usb.mem_free_ptr_out);
		USB_CHECK(epnum==0);
		tntusb_ep_regs[0].out.status = TNTUSB_EP_TYPE_CTRL | TNTUSB_EP_BD_CTRL; /* Type=Control, control mode buffered */
		tntusb_ep_regs[0].in.status  = TNTUSB_EP_TYPE_CTRL | TNTUSB_EP_DT_BIT;  /* Type=Control, single buffered, DT=1 */

		/* Setup the BD pointers */
		tntusb_ep_regs[0].in.bd[0].ptr  = g_usb.mem_free_ptr_in;
		tntusb_ep_regs[0].out.bd[0].ptr = g_usb.mem_free_ptr_out; //for out data
		tntusb_ep_regs[0].out.bd[1].ptr = g_usb.mem_free_ptr_out+desc_edpt->wMaxPacketSize.size; //for setup packet

		tntusb_ep_regs[0].in.bd[0].csr = 0;
		tntusb_ep_regs[0].out.bd[0].csr = 0;
		tntusb_ep_regs[0].out.bd[1].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(8);

		g_usb.mem_free_ptr_out+=desc_edpt->wMaxPacketSize.size+8; //add setup packet
		g_usb.mem_free_ptr_in+=desc_edpt->wMaxPacketSize.size;

		g_usb.ep[epnum].in.mps=desc_edpt->wMaxPacketSize.size;
		g_usb.ep[epnum].out.mps=desc_edpt->wMaxPacketSize.size;
	} else if (dir == TUSB_DIR_OUT) {
		DEBUGMSG("Setting up out endpoint %d, ptr_start=0x%X\n", epnum, g_usb.mem_free_ptr_out);
		USB_CHECK(epnum!=0);
		tntusb_ep_regs[epnum].out.status = type;
		tntusb_ep_regs[epnum].out.bd[0].ptr = g_usb.mem_free_ptr_out;
		tntusb_ep_regs[epnum].out.bd[0].csr = 0; //we'll start receiving when we need to
		g_usb.mem_free_ptr_out+=desc_edpt->wMaxPacketSize.size;
		g_usb.ep[epnum].out.mps=desc_edpt->wMaxPacketSize.size;
	} else {
		DEBUGMSG("Setting up in endpoint %d, ptr_start=0x%X\n", epnum, g_usb.mem_free_ptr_in);
		USB_CHECK(epnum!=0);
		tntusb_ep_regs[epnum].in.status = type;
		tntusb_ep_regs[epnum].in.bd[0].ptr = g_usb.mem_free_ptr_in;
		tntusb_ep_regs[epnum].in.bd[0].csr = 0;
		g_usb.mem_free_ptr_in+=desc_edpt->wMaxPacketSize.size;
		g_usb.ep[epnum].in.mps=desc_edpt->wMaxPacketSize.size;
	}
	return true;
}

//Called when ep is empty, to send part or whole of packet to ep.
//Returns true if all done, false otherwise.
static bool _usb_ep_in_send_more(int epnum) {
	bool finished;
	g_tnt_ep_in_t *epdata=&g_usb.ep[epnum].in;
	int to_send = epdata->xfer_len - epdata->xfer_pos;
	if (to_send != 0 && epdata->xfer_len > 0) {
		int packetlen=to_send;
		if (packetlen > epdata->mps) {
			packetlen = epdata->mps;
		}
		DEBUGMSG("_usb_ep_in_send_more: ep %d pos %d/%d, sending %d more\n", epnum, epdata->xfer_pos, epdata->xfer_len, packetlen);
		_usb_data_write(tntusb_ep_regs[epnum].in.bd[0].ptr, epdata->buffer+epdata->xfer_pos, packetlen);
		tntusb_ep_regs[epnum].in.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(packetlen);
		epdata->xfer_pos += packetlen;
		epdata->cur_plen = packetlen;
		finished = false;
	} else if (epdata->xfer_len == 0) {
		//Zero-byte packet.
		DEBUGMSG("_usb_ep_in_send_more: ep %d sending zero-len packet\n", epnum);
		tntusb_ep_regs[epnum].in.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(0);
		epdata->xfer_len = -1; //make sure we don't send more when this is done sending
		epdata->cur_plen = 0;
		finished = true;
	} else {
		//done
		DEBUGMSG("_usb_ep_in_send_more: no need to send anything anymore\n", epnum);
		finished = true;
	}
	return finished;
}

//Called when data is received in ep, to receive partial or whole packet.
static bool _usb_ep_out_recv_more(int epnum, int len) {
	bool finished;
	g_tnt_ep_out_t *epdata=&g_usb.ep[epnum].out;
	int to_recv = epdata->xfer_len - epdata->xfer_pos;
	if (to_recv != 0 && epdata->xfer_len > 0) {
		DEBUGMSG("_usb_ep_out_recv_more: ep %d pos %d/%d, just received %d more\n", epnum, epdata->xfer_pos, epdata->xfer_len, len);
		_usb_data_read(epdata->buffer + epdata->xfer_pos, tntusb_ep_regs[epnum].out.bd[0].ptr, len);
		epdata->xfer_pos += len;
		finished = false;
		if (len != epdata->mps || epdata->xfer_pos == epdata->xfer_len) {
			finished = true; //short packet; we're done.
		} else {
			//trigger read of the remaining data
			tntusb_ep_regs[epnum].out.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(epdata->mps);
			finished = false;
		}
	} else if (epdata->xfer_len == 0) {
		DEBUGMSG("_usb_ep_out_recv_more: ep %d recv zero-len packet\n", epnum);
		tntusb_ep_regs[epnum].out.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(epdata->mps);
		epdata->xfer_len = -1;
		finished=true;
	} else {
		DEBUGMSG("_usb_ep_out_recv_more: ep %d all done\n", epnum);
		//we should be all done.
		finished = true;
	}
	return finished;
}

bool dcd_edpt_xfer (uint8_t rhport, uint8_t ep_addr, uint8_t * buffer, uint16_t total_bytes) {
	(void) rhport;

	uint8_t const epnum = tu_edpt_number(ep_addr);
	uint8_t const dir   = tu_edpt_dir(ep_addr);
	DEBUGMSG ("dcd_edpt_xfer: ep %d dir %s, len %d\n", epnum, (dir==TUSB_DIR_OUT)?"out":"in", total_bytes);

	if (dir==TUSB_DIR_OUT) {
		//Read data. We'll grab it from the buffer when the out data event triggers.
		g_usb.ep[epnum].out.buffer = buffer;
		g_usb.ep[epnum].out.xfer_pos = 0;
		g_usb.ep[epnum].out.xfer_len = total_bytes;
		tntusb_ep_regs[epnum].out.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(g_usb.ep[epnum].out.mps);
	} else {
		//Start sending data.
		g_usb.ep[epnum].in.buffer = buffer;
		g_usb.ep[epnum].in.xfer_pos = 0;
		g_usb.ep[epnum].in.xfer_len = total_bytes;
		_usb_ep_in_send_more(epnum);
	}
	return true;
}

void dcd_edpt_stall (uint8_t rhport, uint8_t ep_addr) {
	(void) rhport;
	DEBUGMSG("STALL ep %d\n", ep_addr);
	uint8_t const epnum = tu_edpt_number(ep_addr);
	uint8_t const dir = tu_edpt_dir(ep_addr);
	if (epnum == 0) {
		//Need to send the stall packets manually as we can't stall on a setup packet, which also goes out
		//of EP0.
		g_usb.ep0_stall = true;
		if (dir == TUSB_DIR_OUT) {
			tntusb_ep_regs[0].out.bd[0].csr = TNTUSB_BD_STATE_RDY_STALL;
		} else {
			tntusb_ep_regs[0].in.bd[0].csr = TNTUSB_BD_STATE_RDY_STALL;
		}
	} else if (TNTUSB_EP_TYPE_IS_BCI(tntusb_ep_regs[epnum].out.status)) {
		if (dir == TUSB_DIR_OUT && TNTUSB_EP_TYPE_IS_BCI(tntusb_ep_regs[epnum].out.status)) {
			tntusb_ep_regs[epnum].out.status |= TNTUSB_EP_TYPE_HALTED;
		} 
		if (dir == TUSB_DIR_IN && TNTUSB_EP_TYPE_IS_BCI(tntusb_ep_regs[epnum].in.status)) {
			tntusb_ep_regs[epnum].in.status |= TNTUSB_EP_TYPE_HALTED;
		}
	}
}

void dcd_edpt_clear_stall (uint8_t rhport, uint8_t ep_addr) {
	(void) rhport;
	DEBUGMSG("UNSTALL ep %d\n", ep_addr);
	uint8_t const epnum = tu_edpt_number(ep_addr);
	if (epnum==0) {
		//does this do something?
		g_usb.ep0_stall = false;
	} else if (TNTUSB_EP_TYPE_IS_BCI(tntusb_ep_regs[epnum].out.status)) {
		if (tu_edpt_dir(ep_addr) == TUSB_DIR_OUT && TNTUSB_EP_TYPE_IS_BCI(tntusb_ep_regs[epnum].out.status)) {
			tntusb_ep_regs[epnum].out.status &= ~TNTUSB_EP_TYPE_HALTED;
		} 
		if (tu_edpt_dir(ep_addr) == TUSB_DIR_IN && TNTUSB_EP_TYPE_IS_BCI(tntusb_ep_regs[epnum].in.status)) {
			tntusb_ep_regs[epnum].in.status &= ~TNTUSB_EP_TYPE_HALTED;
		}
	}
}

/*------------------------------------------------------------------*/

void usb_poll(void) {
	uint8_t tmpbuf[64]; //note: implies 64b mps

	uint32_t csr=tntusb_regs->csr;

	if (csr & TNTUSB_CSR_BUS_RST_PENDING) {
		if (csr & TNTUSB_CSR_BUS_RST) {
			DEBUGMSG("Reset pending and triggered. Ignoring rest.\n");
			return;
		}
		DEBUGMSG("Reset pending: doing that\n");
		_usb_hw_reset(true);
		dcd_event_bus_signal(0, DCD_EVENT_BUS_RESET, true);
		g_usb.mem_free_ptr_out=0;
		g_usb.mem_free_ptr_in=0;
		tusb_desc_endpoint_t eptd={
			.bEndpointAddress=0,
			.bmAttributes.xfer=TUSB_XFER_CONTROL,
			.wMaxPacketSize.size=64
		};
		dcd_edpt_open(0, &eptd);
	}

	//Note: tntusb is not built to generate an interrupt on SOF, as handling 1000 interrupts a second
	//slows down handling. Additionally, none of TinyUSBs drivers need it. In other words: this
	//code path will be executed way, way less than the expected 1000 times a second.
	if (csr & TNTUSB_CSR_SOF_PENDING) {
		tntusb_regs->ar = TNTUSB_AR_SOF_CLEAR;
		dcd_event_bus_signal(0, DCD_EVENT_SOF, true);
	}

	if (csr & TNTUSB_CSR_EVT_PENDING) {
		uint32_t evt = tntusb_regs->evt;
		DEBUGMSG("usbevt %x\n", evt);

		//Setup handling. Note we only do this when the transactions to in/out ep0 are done, as if they
		//still are running, we should fall through to tell tinyusb about the result of these first.
		uint32_t bds_setup=tntusb_ep_regs[0].out.bd[1].csr;
		if ((tntusb_ep_regs[0].out.bd[1].csr & TNTUSB_BD_STATE_MSK) == TNTUSB_BD_STATE_DONE_OK && 
						g_usb.ep[0].out.buffer==NULL && g_usb.ep[0].in.buffer==NULL) {
			//Setup packet received. Read and ack manually.
			_usb_data_read(tmpbuf, tntusb_ep_regs[0].out.bd[1].ptr, 8);
			DEBUGMSG("Setup packet rcvd:");
			for (int i=0; i<8; i++) DEBUGMSG("%02X ", tmpbuf[i]);
			DEBUGMSG("\n");
			tntusb_ep_regs[0].out.bd[1].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(8);
			//clear in/out stall
			tntusb_ep_regs[0].in.bd[0].csr = 0;
			tntusb_ep_regs[0].out.bd[0].csr = 0;
			g_usb.ep0_stall=false;
			//release lockout
			tntusb_regs->ar = TNTUSB_AR_CEL_RELEASE;
			//Make sure DT=1 for IN endpoint after a SETUP
			tntusb_ep_regs[0].in.status = TNTUSB_EP_TYPE_CTRL | TNTUSB_EP_DT_BIT;
			dcd_event_setup_received(0, tmpbuf, true);
		}

		//handle in endpoints
		for (int ep=0; ep<16; ep++) {
			uint32_t in_csr=tntusb_ep_regs[ep].in.bd[0].csr;
			//ep0 stall gets handled here.
			if (ep==0 && g_usb.ep0_stall) {
				if ((in_csr & TNTUSB_BD_STATE_MSK) != TNTUSB_BD_STATE_RDY_STALL) {
					tntusb_ep_regs[0].in.bd[0].csr = TNTUSB_BD_STATE_RDY_STALL;
				}
			} else if ((in_csr & TNTUSB_BD_STATE_MSK) == TNTUSB_BD_STATE_DONE_ERR) {
				//Re-send packet.
				DEBUGMSG("Error on ep %d. Re-sending %d bytes of data.\n", ep, g_usb.ep[ep].in.cur_plen);
				tntusb_ep_regs[ep].in.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(g_usb.ep[ep].in.cur_plen);
			} else if ((in_csr & TNTUSB_BD_STATE_MSK) == TNTUSB_BD_STATE_DONE_OK) {
				tntusb_ep_regs[ep].in.bd[0].csr=0;
				bool finished=_usb_ep_in_send_more(ep);
				DEBUGMSG("IN xfer done on ep %d: %d bytes - %s\n", ep, g_usb.ep[ep].in.xfer_pos, finished?"all done":"continuing");
				if (finished) {
					dcd_event_xfer_complete(0, ep | 0x80, g_usb.ep[ep].in.xfer_pos, XFER_RESULT_SUCCESS, true);
					g_usb.ep[ep].in.buffer=NULL;
				}
			}
		}
	
		//handle out eps
		for (int ep=0; ep<16; ep++) {
			uint32_t out_csr=tntusb_ep_regs[ep].out.bd[0].csr;
	
			//ep0 stall gets handled here.
			if (ep==0 && g_usb.ep0_stall) {
				if ((out_csr & TNTUSB_BD_STATE_MSK) != TNTUSB_BD_STATE_RDY_STALL) {
					tntusb_ep_regs[0].out.bd[0].csr = TNTUSB_BD_STATE_RDY_STALL;
				}
			} else if ((out_csr & TNTUSB_BD_STATE_MSK) == TNTUSB_BD_STATE_DONE_ERR) {
				//Re-send packet.
				DEBUGMSG("Error on ep %d. Re-triggering receive of mps=%d bytes of data.\n", ep, g_usb.ep[ep].out.mps);
				tntusb_ep_regs[ep].out.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(g_usb.ep[ep].out.mps);
			} else if ((out_csr & TNTUSB_BD_STATE_MSK) == TNTUSB_BD_STATE_DONE_OK) {
				//Note that length includes 2 byte CRC. We subtract that here.
				int len = (out_csr & TNTUSB_BD_LEN_MSK) - 2;
				tntusb_ep_regs[ep].out.bd[0].csr = 0;
				bool finished=_usb_ep_out_recv_more(ep, len);
				DEBUGMSG("OUT xfer done on ep %d: %d bytes - %s\n", ep, len, finished?"all done":"continuing");
				if (finished) {
					DEBUGHEXDUMP(g_usb.ep[ep].out.buffer, g_usb.ep[ep].out.xfer_pos);
					dcd_event_xfer_complete(0, ep,  g_usb.ep[ep].out.xfer_pos, XFER_RESULT_SUCCESS, true);
					g_usb.ep[ep].out.buffer=NULL;
				}
			}
		}
	}
}

