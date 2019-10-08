#include "ext_btn.h"
#include <assert.h>
#include "mach_defines.h"
#include <stdint.h>

extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]


static int _buttons(struct mb_interpreter_t* s, void** l) {
	int result = MB_FUNC_OK;
	mb_assert(s && l);

	mb_check(mb_attempt_open_bracket(s, l));
	mb_check(mb_attempt_close_bracket(s, l));

	mb_check(mb_push_int(s, l, MISC_REG(MISC_BTN_REG)));

	return result;
}

void mybasicext_btn_install(struct mb_interpreter_t* bas) {
	mb_register_func(bas, "BUTTONS", _buttons);
}
