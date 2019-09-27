#include "ext_btn.h"
#include <assert.h>

static int _buttons(struct mb_interpreter_t* s, void** l) {
	int result = MB_FUNC_OK;
	mb_assert(s && l);

	mb_check(mb_attempt_open_bracket(s, l));
	mb_check(mb_attempt_close_bracket(s, l));

	mb_check(mb_push_int(s, l, buttons_get_state()));

	return result;
}

void mybasicext_btn_install(struct mb_interpreter_t* bas) {
	mb_register_func(bas, "BUTTONS", _buttons);
}
