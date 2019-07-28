
#include "tusb_option.h"
#include "device/dcd.h"
#include "dcd_tntusb_hw.h"

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

#define USB_CHECK(x) do { if (!(x)) printf("USB: check fail: " #x " (%s:%d)\n", __FILE__, __LINE__); } while (0)

typedef struct {
	int mem_free_ptr_in;
	int mem_free_ptr_out;
	int ep_mps[16];
	int ep_in_xfer_len[16];
} g_tntusb_t;

static g_tntusb_t g_usb;

static void _usb_data_write(unsigned int dst_ofs, const void *src, int len) {
	/* FIXME unaligned ofs */
	const uint32_t *src_u32 = src;
	volatile uint32_t *dst_u32 = (volatile uint32_t *)((USB_CORE_OFFSET+USB_TXMEM) + dst_ofs);

	len = (len + 3) >> 2;
	while (len--)
		*dst_u32++ = *src_u32++;
}

static void _usb_data_read (void *dst, unsigned int src_ofs, int len) {
	/* FIXME unaligned ofs */
	volatile uint32_t *src_u32 = (volatile uint32_t *)((USB_CORE_OFFSET+USB_RXMEM) + src_ofs);
	uint32_t *dst_u32 = dst;

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
	}

	/* Main control */
	tntusb_regs->csr = (pu ? TNTUSB_CSR_PU_ENA : 0) | TNTUSB_CSR_CEL_ENA | TNTUSB_CSR_ADDR_MATCH | TNTUSB_CSR_ADDR(0);
	tntusb_regs->ar  = TNTUSB_AR_BUS_RST_CLEAR | TNTUSB_AR_SOF_CLEAR | TNTUSB_AR_CEL_RELEASE;
}


/*------------------------------------------------------------------*/
/* Controller API
 *------------------------------------------------------------------*/
void dcd_init (uint8_t rhport) {
	printf("dcd_init()\n");
	(void) rhport;
	/* Main state reset */
	memset(&g_usb, 0x00, sizeof(g_usb));

	/* Reset and enable the core */
	_usb_hw_reset(true);
}

void dcd_int_enable(uint8_t rhport) {
	(void) rhport;
	//ToDo: implement
}

void dcd_int_disable(uint8_t rhport) {
	(void) rhport;
	//ToDo: implement
}

void dcd_set_address (uint8_t rhport, uint8_t dev_addr) {
	printf("dcd_set_address %d\n", dev_addr);
	// Response with status first before changing device address
	dcd_edpt_xfer(rhport, tu_edpt_addr(0, TUSB_DIR_IN), NULL, 0);
	
	//wait till sent
	while ((tntusb_ep_regs[0].in.bd[0].csr & TNTUSB_BD_STATE_MSK) != TNTUSB_BD_STATE_DONE_OK) ;
	tntusb_ep_regs[0].in.bd[0].csr=0;
	//set address
	tntusb_regs->csr = TNTUSB_CSR_PU_ENA | TNTUSB_CSR_CEL_ENA | TNTUSB_CSR_ADDR_MATCH | TNTUSB_CSR_ADDR(dev_addr);
	printf("Address set\n");
}

void dcd_set_config (uint8_t rhport, uint8_t config_num)
{
	printf("dcd_set_config\n");
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
	uint8_t const epnum = tu_edpt_number(desc_edpt->bEndpointAddress);
	uint8_t const dir   = tu_edpt_dir(desc_edpt->bEndpointAddress);
	g_usb.ep_mps[epnum]=desc_edpt->wMaxPacketSize.size;

	int type=0;
	if (desc_edpt->bmAttributes.xfer==TUSB_XFER_CONTROL) type=TNTUSB_EP_TYPE_CTRL;
	if (desc_edpt->bmAttributes.xfer==TUSB_XFER_ISOCHRONOUS) type=TNTUSB_EP_TYPE_ISOC;
	if (desc_edpt->bmAttributes.xfer==TUSB_XFER_BULK) type=TNTUSB_EP_TYPE_BULK;
	if (desc_edpt->bmAttributes.xfer==TUSB_XFER_INTERRUPT) type=TNTUSB_EP_TYPE_INT;

	if (type == TNTUSB_EP_TYPE_CTRL) {
		printf("Setting up control endpoint %d\n", epnum);
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
	} else if (dir == TUSB_DIR_OUT) {
		printf("Setting up out endpoint %d\n", epnum);
		USB_CHECK(epnum!=0);
		tntusb_ep_regs[epnum].out.status = type;
		tntusb_ep_regs[epnum].out.bd[0].ptr = g_usb.mem_free_ptr_out;
		tntusb_ep_regs[epnum].out.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(desc_edpt->wMaxPacketSize.size);
		g_usb.mem_free_ptr_out+=desc_edpt->wMaxPacketSize.size;
	} else {
		printf("Setting up in endpoint %d\n", epnum);
		USB_CHECK(epnum!=0);
		tntusb_ep_regs[epnum].in.status = type;
		tntusb_ep_regs[epnum].in.bd[0].ptr = g_usb.mem_free_ptr_in;
		tntusb_ep_regs[epnum].in.bd[0].csr = 0;
		g_usb.mem_free_ptr_in+=desc_edpt->wMaxPacketSize.size;
	}
	return true;
}

bool dcd_edpt_xfer (uint8_t rhport, uint8_t ep_addr, uint8_t * buffer, uint16_t total_bytes) {
	(void) rhport;

	uint8_t const epnum = tu_edpt_number(ep_addr);
	uint8_t const dir   = tu_edpt_dir(ep_addr);
	printf ("dcd_edpt_xfer: ep %d dir %s, len %d\n", epnum, (dir==TUSB_DIR_OUT)?"out":"in", total_bytes);

	if (dir==TUSB_DIR_OUT) {
		if (buffer) _usb_data_read(buffer, tntusb_ep_regs[epnum].out.bd[0].ptr, total_bytes);
		tntusb_ep_regs[epnum].out.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(g_usb.ep_mps[epnum]);
	} else {
		if (buffer) _usb_data_write(tntusb_ep_regs[epnum].in.bd[0].ptr, buffer, total_bytes);
		tntusb_ep_regs[epnum].in.bd[0].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(total_bytes);
		g_usb.ep_in_xfer_len[epnum]=total_bytes;
	}
	return true;
}

void dcd_edpt_stall (uint8_t rhport, uint8_t ep_addr) {
	(void) rhport;
	printf("STALL ep %d\n", ep_addr);
	uint8_t const epnum = tu_edpt_number(ep_addr);
	tntusb_ep_regs[epnum].out.bd[0].csr |= TNTUSB_BD_STATE_RDY_STALL;
}

void dcd_edpt_clear_stall (uint8_t rhport, uint8_t ep_addr) {
	(void) rhport;
	printf("UNSTALL ep %d\n", ep_addr);
	uint8_t const epnum = tu_edpt_number(ep_addr);
	tntusb_ep_regs[epnum].out.bd[0].csr &= ~TNTUSB_BD_STATE_RDY_STALL;
}

/*------------------------------------------------------------------*/

void usb_poll(void) {
	uint32_t csr=tntusb_regs->csr;
	uint8_t tmpbuf[64]; //note: implies 64b mps

	if (csr & TNTUSB_CSR_BUS_RST_PENDING) {
		if (csr & TNTUSB_CSR_BUS_RST) {
			return;
		}
		printf("Reset pending: doing that\n");
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

	if (csr & TNTUSB_CSR_SOF_PENDING) {
		tntusb_regs->ar = TNTUSB_AR_SOF_CLEAR;
		dcd_event_bus_signal(0, DCD_EVENT_SOF, true);
	}

	//setup handling
	uint32_t bds_setup=tntusb_ep_regs[0].out.bd[1].csr;
	if ((tntusb_ep_regs[0].out.bd[1].csr & TNTUSB_BD_STATE_MSK) == TNTUSB_BD_STATE_DONE_OK) {
		//Setup packet received. Read and ack manually.
		_usb_data_read(tmpbuf, tntusb_ep_regs[0].out.bd[1].ptr, 8);
		printf("Setup packet rcvd:");
		for (int i=0; i<8; i++) printf("%02X ", tmpbuf[i]);
		printf("\n");
		tntusb_ep_regs[0].out.bd[1].csr = TNTUSB_BD_STATE_RDY_DATA | TNTUSB_BD_LEN(8);
		//clear in/out
		tntusb_ep_regs[0].in.bd[0].csr = 0;
		tntusb_ep_regs[0].out.bd[0].csr = 0;
		//Make sure DT=1 for IN endpoint after a SETUP
		tntusb_ep_regs[0].in.status = TNTUSB_EP_TYPE_CTRL | TNTUSB_EP_DT_BIT;
		dcd_event_setup_received(0, tmpbuf, true);
		tntusb_regs->ar = TNTUSB_AR_CEL_RELEASE;
	}

	//handle endpoints
	for (int ep=0; ep<16; ep++) {
		uint32_t in_csr=tntusb_ep_regs[ep].in.bd[0].csr;
		if ((in_csr & TNTUSB_BD_STATE_MSK) == TNTUSB_BD_STATE_DONE_OK) {
			printf("IN xfer done on ep %d: %d bytes\n", ep, g_usb.ep_in_xfer_len[ep]);
			tntusb_ep_regs[ep].in.bd[0].csr=0;
			dcd_event_xfer_complete(0, ep, g_usb.ep_in_xfer_len[ep], XFER_RESULT_SUCCESS, true);
		}
		uint32_t out_csr=tntusb_ep_regs[ep].out.bd[0].csr;
		if ((out_csr & TNTUSB_BD_STATE_MSK) == TNTUSB_BD_STATE_DONE_OK) {
			printf("OUT xfer done on ep %d: %d bytes\n", ep, out_csr & TNTUSB_BD_LEN_MSK);
			dcd_event_xfer_complete(0, ep, out_csr & TNTUSB_BD_LEN_MSK, XFER_RESULT_SUCCESS, true);
		}
	}
}

