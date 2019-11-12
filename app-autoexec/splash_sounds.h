
void pcm_fill_switch();
static mach_int_frame_t * audio_interrupt_handler_switch(mach_int_frame_t *frame, int int_no);

void pcm_fill_sega();
static mach_int_frame_t * audio_interrupt_handler_sega(mach_int_frame_t *frame, int int_no);

void pcm_fill_playstation();
static mach_int_frame_t * audio_interrupt_handler_playstation(mach_int_frame_t *frame, int int_no);

void pcm_fill_xbox();
static mach_int_frame_t * audio_interrupt_handler_xbox(mach_int_frame_t *frame, int int_no);

void synth_play_gameboy_monochrome(void);
void synth_play_gameboy_color(void);
void synth_play_switch(void);
void synth_play_sega(void);
void synth_play_playstation(void);
void synth_play_xbox(void);

