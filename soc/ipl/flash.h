#include <stdint.h>
#include <stdbool.h>
#pragma once

#define FLASH_SEL_INT 0
#define FLASH_SEL_CART 1

uint32_t flash_get_id(int flash_sel);
uint64_t flash_get_uid(int flash_sel);
void flash_read(int flash_sel, uint32_t addr, uint8_t *buff, int len);
uint8_t flash_read_status(int flash_sel, int reg);
bool flash_write_status(int flash_sel, int reg);
bool flash_write_enable(int flash_sel);
bool flash_wait_idle(int flash_sel);

bool flash_program(int flash_sel, uint32_t addr, const uint8_t *buff, int len);

//Will automatically choose best set of flash erase instructions (4k, 32k, 64k) but obviously cannot
//erase ranges not starting or ending on a 4k offset.
bool flash_erase_range(int flash_sel, int addr, int len);
bool flash_wake(int flash_sel);
