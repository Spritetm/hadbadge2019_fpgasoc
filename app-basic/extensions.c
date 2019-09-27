#include "extensions.h"
//#include "ext_gfx.h"
#include "ext_btn.h"

void mybasicext_install(struct mb_interpreter_t* bas) {
//	mybasicext_gfx_install(bas);
	mybasicext_btn_install(bas);
}