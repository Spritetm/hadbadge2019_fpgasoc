/* vim: ts=4 st=4 : */

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"

#include "golden-FN-16c.xpm"

//Pointer to the framebuffer memory.
uint8_t *fbmem;

//The dimensions of the framebuffer
#define FB_WIDTH  512
#define FB_HEIGHT 320

//Convenience macros
#define COMP_COLOR(A, R, G, B) ((((A) & 0xFF) << 24) | \
								(((B) & 0xFF) << 16) | \
								(((G) & 0xFF) <<  8) | \
								(((R) & 0xFF) <<  0))
#define FB_PIX(X, Y) fbmem[(X) + ((Y) * FB_WIDTH)]

/*
void create_fire_palette(void) {

	// transparent to blue (leaving the first 16 for the tileset)
	// this could be as well just black to blue, but why not. :)
	for (int i = 0; i < 16; i++) {
		GFXPAL[i+17] = COMP_COLOR(i << 2, 0, 0, i << 2);
	}

	// setting the remaining palette in one go
	for (uint32_t i = 0; i < 32; i++) {
		// blue to red
		GFXPAL[i +  32] = COMP_COLOR(0xFF, i << 3, 0, 64 - (i << 1));
		// red to yellow
		GFXPAL[i +  64] = COMP_COLOR(0xFF, 0xFF, i << 3, 0);
		// yellow to white
		GFXPAL[i +  96] = COMP_COLOR(0xFF, 0xFF, 0xFF,   0 + (i << 2));
		GFXPAL[i + 128] = COMP_COLOR(0xFF, 0xFF, 0xFF,  64 + (i << 2));
		GFXPAL[i + 160] = COMP_COLOR(0xFF, 0xFF, 0xFF, 128 + (i << 2));
		GFXPAL[i + 192] = COMP_COLOR(0xFF, 0xFF, 0xFF, 192 + i);
		GFXPAL[i + 224] = COMP_COLOR(0xFF, 0xFF, 0xFF, 224 + i);
	}
}
*/

//Here is where the party begins
void main(int argc, char **argv) {
	int ii,i,j=0,k=0,n=0;
	int dx,dy,cc,cr,cg,cb,c1,c2,c3;
	int ac[16],ar[16],ag[16],ab[16];
	char *po,ch;
	uint8_t *pb;
	// Blank out fb while we're loading stuff by disabling all layers. This
	// just shows the background color.
	GFX_REG(GFX_BGNDCOL_REG)=0x202020; //a soft gray
	GFX_REG(GFX_LAYEREN_REG)=0; //disable all gfx layers

	unsigned char* fbmem = (unsigned char*)calloc(FB_WIDTH, FB_HEIGHT);

	FILE *f;
	f=fopen("/dev/console", "w");
	setvbuf(f, NULL, _IONBF, 0); //make console line unbuffered
	// Note that without the setvbuf command, no characters would be printed
	// until 1024 characters are buffered. You normally don't want this.
	fprintf(f, "\033C"); //clear the console. Note '\033' is the escape character.
	fprintf(f, "SHAOS SHAOS SHAOS SHAOS SHAOS\n");
#if 0
	for(i=0;i<256;i++)
	{
		if((i&15)==0) fprintf(f,"%1XX:",i>>4);
		if((i>>4)<2)
		{
			if((i&15)==0) fprintf(f,"\n");
			continue;
		}
		fprintf(f,"%c",i);
		if((i&15)==15) fprintf(f,"\n");
	}
	fprintf(f, "10X\n______________________________");
#else
	fprintf(f,"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
#endif
	fprintf(f,"nedoPC - Spirit Retro Handheld");
	// Reenable the tile layer to show the above text
#if 0
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_TILEA;
	for(i=0;i<16;i++)
	{
		GFXTILEMAPA[(1<<6)+i+3]=i;
		GFXTILEMAPA[(2<<6)+i+3]=0x10|i;
		GFXTILEMAPA[(17<<6)+i+3]=0x100|i;
	}
#else
	GFX_REG(GFX_FBPITCH_REG)=(17<<GFX_FBPITCH_PAL_OFF)|(FB_WIDTH<<GFX_FBPITCH_PITCH_OFF);
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)fbmem);
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_TILEA|GFX_LAYEREN_FB|GFX_LAYEREN_FB_8BIT;
	sscanf(golden_FN_16c_xpm[0],"%d %d %d %d",&dx,&dy,&cc,&j);
//	fprintf(f,"dx=%i dy=%i cc=%i bb=%i",dx,dy,cc,j);
	j = 1;
	for(i=0;i<cc;i++)
	{
		ac[i] = golden_FN_16c_xpm[j][0];
		po = strstr(golden_FN_16c_xpm[j++],"c #");
		if(po!=NULL) k=(int)strtol(&po[3],NULL,16);
		else k=0;
		cb = k&255;
		cg = (k>>8)&255;
		cr = (k>>16)&255;
//		GFXPAL[17+i] = cr|(cg<<8)|(cb<<16)|(0xFF<<24);
		ar[i] = cr;
		ag[i] = cg;
		ab[i] = cb;
	}
	for(k=0;k<256;k++)
	{
		c1 = k>>4;
		c2 = k&15;
		cr = (((ar[c1] + ar[c1] + ar[c2])<<8)*85)>>16;
		cg = (((ag[c1] + ag[c1] + ag[c2])<<8)*85)>>16;
		cb = (((ab[c1] + ab[c1] + ab[c2])<<8)*85)>>16;
		GFXPAL[17+k] = COMP_COLOR(0xFF,cr,cg,cb);
	}
	for(k=0;k<288;k++)
	{
		ii = 0;
		for(i=0;i<720;i+=3)
		{
			pb = &FB_PIX(ii,k+16);
			pb[0] = 0;
			pb[1] = 0;
			c1 = c2 = c3 = 0;
#if 0
			if(k&1) c1 = c2 = c3 = 1;
#else
			ch = golden_FN_16c_xpm[j][i+8];
			for(n=0;n<cc;n++) if(ac[n]==ch) break;
			if(n<cc) c1 = n;
			ch = golden_FN_16c_xpm[j][i+9];
			for(n=0;n<cc;n++) if(ac[n]==ch) break;
			if(n<cc) c2 = n;
			ch = golden_FN_16c_xpm[j][i+10];
			for(n=0;n<cc;n++) if(ac[n]==ch) break;
			if(n<cc) c3 = n;
#endif
			pb[0] = (c1<<4)|c2;
			pb[1] = (c3<<4)|c2;
			ii+=2;
		}
//		if(k&1)
		j++;
	}
#endif
	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);
	// Wait until button A is released
	while (MISC_REG(MISC_BTN_REG));
	//Wait until button A is pressed
	while ((MISC_REG(MISC_BTN_REG) & BUTTON_A)==0)
#if 1
	;
#else
	{
		while((++j&0x3F));
		GFX_REG(GFX_BGNDCOL_REG)=((++i)&1)*0xFFFF+(j<<16);
	}
#endif
}
