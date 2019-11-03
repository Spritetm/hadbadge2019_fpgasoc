#include <stdint.h>

/**
 Load a tilemap in tmx format, as output by tiled. Only loads csv-formatted data, does not load embedded tilesets
 (use gfx_load_tiles_mem for that). You can either load into a memory buffer, for large tilemaps (e.g. entire
 levels of games), or directly into the hardware tilemap a or b memories. In the latter case, tilemaph and
 tilemapw should be 64.

 How to create something compatible in tiled:
 - Create a tilemap png. 16x16 tiles, 512 tiles max. Draw, cut/paste, whatever, all your tiles. Note
   that tile 0 is used as 'no tile', suggest making that entirely transparent. If you're going
   to use the tiles for sprites, make sure palette color index 0 is fully transparent.
 - Start tiled. Select 'new tileset'. Type must be 'based on image', do not select 'embed in map'.
   Select the png you just created as png, set tile width/height to 16/16 and offsets to 0/0.
 - Save the tileset
 - Select 'New Map' to create the tilemap. Orientation is orthogonal, tile layer format *must be* csv,
   tile render order is 'right down'. Map size is 64x64 or less if you directly want to load the
   tilemap into hardware tile memory; it can be more if you manually copy bits over to tile memory.
   Tile size should be 16x16 again.
 - Draw your map. Feel free to flip/rotate tiles, the hardware supports it.
 - When done, make sure your app can get at the data in the resulting tilemap tmx file. Either
   embed it in your app using BINFILES in the app Makefile, or copy it over to flash as a file
   and read the data from it using fopen/fread/... .
 - Feed the data to this function to convert the tilemap into something the hardware can understand.
 - Feed the png containing the tiles into gfx_load_tiles_mem to also load the tiles themselves

 @param tilemap The tilemap to save the tile data into. Can either be GFXTILEMAPA/GFXTILEMAPB
                to directly load to the gfx hardware, or a buffer in memory if you need to preprocess
                it somehow.
 @param tilemaph Height of the target tilemap memory, in tiles. Use 64 when using GFXTILEMAP[A|B].
 @param tilemapw Width of the target tilemap memory, in tiles. Use 64 when using GFXTILEMAP[A|B].
 @param layerid Layer ID of the Tile Layer in the tmx file to load. Use 1 unless you have multiple 
        layers defined in the map file.
 @param tilemapstr Pointer to the contents of the tmx file.
 @param tilemaplen Length of tmx file, or -1 if tilemapstr is zero-terminated.
 @param palstart Start index of palette used for tiles. Must be divisable by 8.
 @returns 
*/
int gfx_load_tilemap_mem(uint32_t *tilemap, int tilemaph, int tilemapw, int layerid, const char *tilemapstr, int tilemaplen, int palstart);

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
*/
int gfx_load_tiles_mem(uint32_t *tilemem, uint32_t *palettemem, char *pngstart, int pnglen);

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

/*
Note on TGA files: Type 1 and 9 (indexed colors, either with or without RLE compression)
are supported by these routines. Tga files in general load quicker and require way, way
less memory to load than pngs. The downside is that they tend to be larger.

An added advantage is that targa files can be read using streaming techniques rather than
needing the file to be entirely in memory, which also helps with speed and memory usage.
*/

/**
 Callback for the targa file format reader. The reader should read up to len bytes and return a pointer
 to the result. The targa routines guarantee that they will never read more than 256 bytes, so you
 can allocate a static buffer for that in arg if you need it.

 @param len Length of data to read
 @param[out] retlen Length actually read
 @param arg Opaque argument as passed to gfx_load_*_tga
 @return Pointer to read data
 */
typedef uint8_t* (*tga_read_fn_t)(int len, int *retlen, void *arg);

/**
 Load a tga file, using a reader callback, into a buffer that can be used as a framebuffer. As a side effect,
 also writes out the palette.
 @param fbmem Memory to write pixeldata into. Can be an actual framebuffer.
 @param palmem Memory to write the RGBA palette data into. Data will be written
               incrementally from palmem[0] on.
 @param fbbpp Bit-per-pixel of the framebuffer memory. Either 4 or 8, for 16-color or 256-color tgas.
 @param readfn Reader function
 @param arg Opaque arg passed to readfn
 @returns 0 on success, other on failure.
 */
int gfx_load_fb_tga(uint8_t *fbmem, uint32_t *palmem, int fbbpp, int pitch, tga_read_fn_t readfn, void *arg);

/**
 Load a tga file, already in memory, into a buffer that can be used as a framebuffer. As a side effect,
 also writes out the palette.
 @param fbmem Memory to write pixeldata into. Can be an actual framebuffer.
 @param palmem Memory to write the RGBA palette data into. Data will be written
               incrementally from palmem[0] on.
 @param fbbpp Bit-per-pixel of the framebuffer memory. Either 4 or 8, for 16-color or 256-color tgas.
 @param tgastart Pointer to start of tga data
 @param tgalen Length of tga data
 @returns 0 on success, other on failure.
 */
int gfx_load_fb_tga_mem(uint8_t *fbmem, uint32_t *palmem, int fbbpp, int pitch, char *tgastart, int tgalen);


/**
 Load a tga file, using a reader callback, into a buffer that can either be or be copied to tile memory. 
 As a side effect, also writes out the palette.
 @param tilemem Memory to write pixeldata into. Can be (a pointer into) the actual tile memory.
 @param palettemem Memory to write the RGBA palette data into. Data will be written
               incrementally from palmem[0] on.
 @param readfn Reader function
 @param arg Opaque arg passed to readfn
 @returns 0 on success, other on failure
*/
int gfx_load_tiles_tga(uint32_t *tilemem, uint32_t *palettemem, tga_read_fn_t readfn, void *arg);

/**
 Load a tga file, already in memory, into a buffer that can either be or be copied to tile memory. 
 As a side effect, also writes out the palette.
 @param tilemem Memory to write pixeldata into. Can be (a pointer into) the actual tile memory.
 @param palettemem Memory to write the RGBA palette data into. Data will be written
               incrementally from palmem[0] on.
 @param tgastart Pointer to start of tga data
 @param tgalen Length of tga data
 @returns 0 on success, other on failure
*/
int gfx_load_tiles_tga_mem(uint32_t *tilemem, uint32_t *palmem, char *tgastart, int tgalen);


