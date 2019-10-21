#include <stdint.h>

/**
 Load a png file, already in memory, into a buffer that can be used as a framebuffer. As a side effect,
 also writes out the palette.
 @param fbmem Memory to write pixeldata into. Can be an actual framebuffer.
 @param palmem Memory to write the RGBA palette data into. Data will be written
               incrementally from palmem[0] on.
 @param fbbpp Bit-per-pixel of the framebuffer memory. Either 4 or 8, for 16-color or 256-color pngs.
 @param pngstart Pointer to start of png data
 @param pnglen Length of png data
 @returns 0 on success, other on failure (lodepng_decode error)
*/
int gfx_load_fb_mem(uint8_t *fbmem, uint32_t *palmem, int fbbpp, int pitch, char *pngstart, int pnglen);

/**
 Load a png file, already in memory, into a buffer that can either be or be copied to tile memory. 
 As a side effect, also writes out the palette.
 @param tilemem Memory to write pixeldata into. Can be (a pointer into) the actual tile memory.
 @param palettemem Memory to write the RGBA palette data into. Data will be written
               incrementally from palmem[0] on.
 @param pngstart Pointer to start of png data
 @param pnglen Length of png data
 @returns 0 on success, other on failure (lodepng_decode error)
*/int gfx_load_tiles_mem(uint32_t *tilemem, uint32_t *palettemem, char *pngstart, int pnglen);

/**
 Helper function for grabbing a pixel value from a decoded, indexed png file.
 @param pdat data as returned by a lodepng decode function
 @param x xpos of pixel to resolve
 @param y ypos of pixel to resolve
 @param w Width of the png file
 @param h Height of the png file
 @param bpp Bit per pixel (1, 2, 4, 8) of the png file.
*/
inline static uint8_t png_resolve_pixel(const unsigned char *pdat, int x, int y, int w, int h, int bpp) {
	int adr=x+w*y;
	if (bpp==8) {
		return pdat[adr];
	} else if (bpp==4) {
		int c=pdat[adr/2];
		if ((adr&1)==0) return (c>>4)&0xf;
		if ((adr&1)==1) return (c>>0)&0xf;
	} else if (bpp==2) {
		int c=pdat[adr/4];
		if ((adr&3)==0) return (c>>6)&0x3;
		if ((adr&3)==1) return (c>>4)&0x3;
		if ((adr&3)==2) return (c>>2)&0x3;
		if ((adr&3)==3) return (c>>0)&0x3;
	} else if (bpp==1) {
		int c=pdat[adr/8];
		return c>>(7-(adr&7));
	} else {
		return 0;
	}
}
