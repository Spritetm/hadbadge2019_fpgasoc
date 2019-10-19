#include <stdint.h>
#pragma once

#define INT_NO_TIMER 0
#define INT_NO_ILLINSTR 1
#define INT_NO_UNALIG 2
#define INT_NO_BUSERR 3
#define INT_NO_USB 4

//Register file in the format the interrupt handler saves it
typedef struct {
	uint32_t x[32]; //note: pc is stored in x[0]. x0 always reads 0 in hw, so we don't need to save that.
} mach_int_frame_t;

typedef mach_int_frame_t* (*mach_int_handler_p)(mach_int_frame_t *frame);

extern mach_int_handler_p interrupt_vector_table[32];

static inline mach_int_handler_p mach_set_int_handler(int intno, mach_int_handler_p handler) {
	if (intno==INT_NO_BUSERR) {
		//Refuse to set this. Clear_int_handler() needs it.
		return NULL;
	}
	mach_int_handler_p ret=interrupt_vector_table[intno];
	interrupt_vector_table[intno]=handler;
	return ret;
}

static inline mach_int_handler_p mach_clear_int_handler(int intno) {
	return mach_set_int_handler(intno, interrupt_vector_table[INT_NO_BUSERR]);
}

//These routines are in mach_interrupt_asm.S

//Enable the interrupts given in the bitmask
//Note this should be given e.g. (1<<INT_NO_USB) as argument.
void mach_int_ena(uint32_t mask);
//Disble the interrupts given in the bitmask
//Note this should be given e.g. (1<<INT_NO_USB) as argument.
void mach_int_dis(uint32_t mask);

