
	Processor 16f84
	include "p16f84.inc"

_ResetVector set 0x00
_IntVector set 0x04

gpioa equ 5
gpiob equ 6


	ORG _ResetVector
	goto start

	ORG _IntVector
	goto int


start:
	movfw PORTA
	movwf PORTA
	movfw PORTB
	movwf PORTB
	goto start

int:
	retfie


	end
