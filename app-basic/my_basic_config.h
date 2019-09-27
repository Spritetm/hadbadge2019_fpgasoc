#include <stdint.h>
#include <memory.h>
#include <assert.h>
#include <ctype.h>
#include <float.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ext_intliteral_strtol.h"

#define MB_DISABLE_LOAD_FILE
#undef MB_MANUAL_REAL_FORMATTING

/* Define as 1 to create hash table nodes lazily, 0 obligingly */
#define _LAZY_HASH_TABLE 0
/* Define as 1 to treat warning as error, 0 just leave it */
#define _WARNING_AS_ERROR 1
/* Define as 1 to automatically raise error during popping argument, 0 just return an error result */
#define _SIMPLE_ARG_ERROR 1
/* Define as 1 to use a comma to PRINT a new line, 0 to use a semicolon */
#define _COMMA_AS_NEWLINE 0
/* Define as 1 to enable multiline statement */
#define _MULTILINE_STATEMENT 1

/* Hash table size */
#define _HT_ARRAY_SIZE_TINY 1
#define _HT_ARRAY_SIZE_SMALL 193
#define _HT_ARRAY_SIZE_MID 1543
#define _HT_ARRAY_SIZE_BIG 12289
#define _HT_ARRAY_SIZE_DEFAULT _HT_ARRAY_SIZE_SMALL

/* Max length of a single symbol */
#define _SINGLE_SYMBOL_MAX_LENGTH 128

/* Buffer length of some string operations */
#define _INPUT_MAX_LENGTH 256
#define _TEMP_FORMAT_MAX_LENGTH 32
#define _LAMBDA_NAME_MAX_LENGTH 32

/* Localization specifier */
#define _LOCALIZATION_USEING 1
#define _LOCALIZATION_STR ""

/* Helper */
#ifdef MB_COMPACT_MODE
#	define _PACK1 : 1
#	define _PACK2 : 2
#	define _PACK8 : 8
#else /* MB_COMPACT_MODE */
#	define _PACK1
#	define _PACK2
#	define _PACK8
#endif /* MB_COMPACT_MODE */

#define _UNALIGNED_ARG

#ifndef sgn
#	define sgn(__v) ((__v) ? ((__v) > 0 ? 1 : -1) : 0)
#endif /* sgn */

#ifndef islower
#	define islower(__c) ((__c) >= 'a' && (__c) <= 'z')
#endif /* islower */
#ifndef toupper
#	define toupper(__c) (islower(__c) ? ((__c) - 'a' + 'A') : (__c))
#endif /* toupper */

#ifndef countof
#	define countof(__a) (sizeof(__a) / sizeof(*(__a)))
#endif /* countof */

#ifndef _mb_check_exit
#	define _mb_check_exit(__expr, __exit) do { if((__expr) != MB_FUNC_OK) goto __exit; } while(0)
#endif /* _mb_check_exit */
#ifndef _mb_check_mark_exit
#	define _mb_check_mark_exit(__expr, __result, __exit) do { __result = (__expr); if(__result != MB_FUNC_OK) goto __exit; } while(0)
#endif /* _mb_check_mark_exit */

#define mb_strtol(__s, __e, __r) vbequiv_strtol((__s), (__e), (__r))
