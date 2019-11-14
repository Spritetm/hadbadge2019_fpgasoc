/*
 *	Badge utilities for time keeping
 */

#include <stdint.h>

/*
 *	Following example of Arduino: the number of milliseconds since the badge
 *	started running. And just like Arduino, the 32-bit return value will
 *	overflow in about 50 days.
 */
uint32_t millis();

/*
 *	Following example of Arduino: wait a given of milliseconds before
 *	returning to caller. We may perform background housekeeping while
 *	we wait.
 */
void delay(uint32_t ms);

/*
 *	Wait for button press
 */
void wait_for_button_press(uint32_t button_mask);

/*
 *	Wait for button release
 */
void wait_for_button_release();

/*
 *	Wait for VBlank frame count greater than given frame
 */
void wait_for_next_frame(uint32_t current_frame);
