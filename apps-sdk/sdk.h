/*
 * Copyright 2019 Jeroen Domburg <jeroen@spritesmods.com>
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
 */
#ifndef HACKADAY_SOC_SDK_H
#define HACKADAY_SOC_SDK_H

#include <stdint.h>

// these hardware addresses are resolved at link time from
// the ldscript.ld in the gloss folder and map to virtual
// support hardware defined for the default RISC-V SOC

// see soc/ipl/gloss/mach_defines.h for information on
// the various register offsets and values

extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]

extern volatile uint32_t UART;
#define UART_REG(i) UART[(i)/4]

extern volatile uint32_t LCD;
#define LCD_REG(i) LCD[(i)/4]

extern volatile uint32_t USB;
#define USB_REG(i) USB[(i)/4]

extern volatile uint32_t GFXREG[];
#define GFX_REG(i) GFXREG[(i)/4]

extern uint32_t GFXPAL[];
extern uint32_t GFXTILES[];
extern uint32_t GFXSPRITES[];
extern uint32_t GFXTILEMAPA[];
extern uint32_t GFXTILEMAPB[];

#endif // HACKADAY_SOC_SDK_H
