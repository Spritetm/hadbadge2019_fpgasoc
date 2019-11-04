#pragma once

extern volatile uint32_t SYNTH[];
#define SYNTHREG(i) SYNTH[i/4]

void play(uint8_t voice, uint16_t pitch, uint16_t duration);
void play_midi_note(uint8_t voice, uint8_t midi_note_num, uint16_t duration);
void set_dynamics(uint8_t voice, uint8_t attack, uint8_t release);
void set_volume(uint16_t volume);
void pcm_audio(uint16_t sample);
