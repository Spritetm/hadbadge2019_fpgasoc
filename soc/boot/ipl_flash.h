#include <stdint.h>
#include <stdbool.h>
#pragma once

#define FLASH_SEL_INT 0
#define FLASH_SEL_CART 1

uint32_t flash_get_id(int flash_sel);
void flash_read(int flash_sel, uint32_t addr, uint8_t *buff, int len);
bool flash_wake(int flash_sel);
