;****************************************************************************
;* Filename: LEDctrl.asm
;****************************************************************************
;* Revision: Rev0
;* Date:     08-16-2019
;****************************************************************************
;* Note: 
;* Clock: 6.14 MHz

len	equ	16	; 
w	equ	1
f	equ	0

;----------------------------------------------------------- proc def
	list	p=16f84a
	list	R=dec
	include	"p16f84a.inc"
	include	"macros.inc"
;----------------------------------------------------------- config
	__CONFIG  _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _CP_OFF	; HS osc / no WDT / pwrt on / code not protected


;----------------------------------------------------------- ram def
	CBLOCK	0x20	; GP RAM bank 0x20-0x6F (all words little endian)

dim_period		; one step period (must be >0)
ramp_factor		; ramp speed up (must be >0)
preset_a		; new A leds 012, preset by user routine (bit 0 left)
preset_b		; new B leds 012345, preset by user routine (bit 0 left)
pattern			; patern selected (if 0 then no pattern, write to preset_x manually)

target_b		; OUTB target values (bit 0 first)
target_a		; OUTA target values (bit 0 first)
slow_b			; OUTB medial values, dynamically loaded (bit 0 first)
slow_a			; OUTA medial values, dynamically loaded (bit 0 first)
count_b			; OUTB count values, dynamically decremented (bit 0 first)
count_a			; OUTA count values, dynamically decremented (bit 0 first)

inner_count		; inner loop counter
outer_count		; outer loop counter
broad_count		; slow down counter inside one step
pat_count		; pattern step countdown
count_dim		; tempo counter inside one step
tempw			; temporary gp
flag			; bit 0: A active, bit 1: B active

	ENDC
; Initial definitions:
#define	outb	PORTB		; bits 012345 only
#define	outa	PORTA		; bits 012    only
#define	step	dim_period	; one step period (must be >0)
#define	speedup	ramp_factor	; ramp speed up (must be >0)

;----------------------------------------------------------- code
	CODE
	goto	start

;----------------------------------------------------------- gamma table
; LED intensity physiological adjustment table, gamma=2 (input w=0-127, output w=1-253)
; fractional power of 2, multiplied by 2 (that's why it's /64 and not /128) and inc by 1
; note: table must not cross the page boundary
	org	1
gamma2
	addwf	PCL,f
    variable xx
xx=0
    while xx<128
	retlw	xx*xx/64+1
xx+=1
    endw

pat2			; wave from right to left
	addwf	PCL,f
	retlw	b'100000'
	retlw	b'110000'
	retlw	b'111000'
	retlw	b'111100'
	retlw	b'111110'
	retlw	b'011111'
	retlw	b'001111'
	retlw	b'000111'
	retlw	b'000011'
	retlw	b'000001'
	retlw	0x80	; terminator
pat3			; wave from left to right
	addwf	PCL,f
	retlw	b'000001'
	retlw	b'000011'
	retlw	b'000111'
	retlw	b'001111'
	retlw	b'011111'
	retlw	b'111110'
	retlw	b'111100'
	retlw	b'111000'
	retlw	b'110000'
	retlw	b'100000'
	retlw	0x80
pat4			; wave from center
	addwf	PCL,f
	retlw	b'000000'
	retlw	b'001100'
	retlw	b'011110'
	retlw	b'111111'
	retlw	b'110011'
	retlw	b'100001'
	retlw	0x80
pat5			; wave to center
	addwf	PCL,f
	retlw	b'000000'
	retlw	b'100001'
	retlw	b'110011'
	retlw	b'111111'
	retlw	b'011110'
	retlw	b'001100'
	retlw	0x80
pat6			; alternating pattern 111000
	addwf	PCL,f
	retlw	b'111000'
	retlw	b'000111'
	retlw	0x80
pat7			; alternating pattern 101010
	addwf	PCL,f
	retlw	b'010101'
	retlw	b'101010'
	retlw	0x80
pat8			; all blink
	addwf	PCL,f
	retlw	b'000000'
	retlw	b'111111'
	retlw	0x80
pat9			; alternating wave pattern
	addwf	PCL,f
	retlw	b'100000'
	retlw	b'110000'
	retlw	b'111000'
	retlw	b'111100'
	retlw	b'111110'
	retlw	b'111111'
	retlw	b'111110'
	retlw	b'111100'
	retlw	b'111000'
	retlw	b'110000'
	retlw	b'100000'
	retlw	b'000001'
	retlw	b'000011'
	retlw	b'000111'
	retlw	b'001111'
	retlw	b'011111'
	retlw	b'111111'
	retlw	b'011111'
	retlw	b'001111'
	retlw	b'000111'
	retlw	b'000011'
	retlw	b'000001'
	retlw	0x80
pat10			; drop pattern
	addwf	PCL,f
	retlw	b'100000'
	retlw	b'010000'
	retlw	b'001000'
	retlw	b'000100'
	retlw	b'100010'
	retlw	b'010001'
	retlw	b'001001'
	retlw	b'000101'
	retlw	b'100011'
	retlw	b'010011'
	retlw	b'001011'
	retlw	b'000111'
	retlw	b'100111'
	retlw	b'010111'
	retlw	b'001111'
	retlw	b'101111'
	retlw	b'011111'
	retlw	b'011111'
	retlw	b'111110'
	retlw	b'111110'
	retlw	b'111101'
	retlw	b'111100'
	retlw	b'111010'
	retlw	b'111001'
	retlw	b'111000'
	retlw	b'110100'
	retlw	b'110010'
	retlw	b'110001'
	retlw	b'101000'
	retlw	b'100100'
	retlw	b'100010'
	retlw	b'010001'
	retlw	b'001000'
	retlw	b'000100'
	retlw	b'000010'
	retlw	b'000001'
	retlw	0x80
pat11			; breath
	addwf	PCL,f
	retlw	b'000000'
	retlw	b'001100'
	retlw	b'011110'
	retlw	b'111111'
	retlw	b'011110'
	retlw	b'001100'
	retlw	0x80

;----------------------------------------------------------- SFR ini
start
	bsf	STATUS,RP0
	movlw	b'00000000'
	movwf	TRISA
	movlw	b'00000000'
	movwf	TRISB
	bcf	STATUS,RP0
	movlw	b'00000000'
	movwf	PORTA
	movlw	b'00000000'
	movwf	PORTB

	movlw	0x0c
	movwf	FSR		; FSR = dst ptr for clr
zeros
	clrf	INDF		; clr one byte
	incf	FSR,f		; adv dst ptr
	btfss	FSR,7		; test if end of RAM...
	goto	zeros		; ...if not, loop

	bsf	flag,0		; leds A active
	bsf	flag,1		; leds B active

	movlw	1		; period (1: fastest) (must be >0)
	movwf	step
	movlw	8		; ramp (1: slowest) (8: ramp=cycle) (must be >0)
	movwf	speedup

	movlw	4
	movwf	pattern

;----------------------------------------------------------- farm

	incf	step,w
	movwf	count_dim	; initialize tempo count
farm				; outer loop
; inner loop #1:
; after [step] passes, [slow] approaches to [target]
; performing INC or DEC or NOP (no chase)
; so [step] is a timing constant for dim tempo

	decf	count_dim,f
	ifnz
	goto	no_chase

	incf	step,w
	movwf	count_dim	; reinitialize tempo count

	movf	speedup,w
	movwf	inner_count
speedup_loop
	chase_b	0		; [slow] approach (inc or dec) to [target]
	chase_b	1
	chase_b	2
	chase_b	3
	chase_b	4
	chase_b	5
	chase_a	0
	chase_a	1
	chase_a	2
	decfsz	inner_count,f
	goto	speedup_loop
no_chase

; inner loop #2:
; after 2048 passes, [preset_a:1] and [preset_b:1] will increment and redefine [target:9]
; making one step through the pattern

	incf	outer_count,w
	andlw	0x1f
	movwf	outer_count
	ifnz
	goto	rough
			; every 32th pass
	incf	broad_count,f
	movf	broad_count,w
	subwf	step,w		; NC if step < broad_count
	ifc
	goto	rough
	clrf	broad_count
			; every step*32th pass (moment for new set)
	movf	pattern,w
	movwf	inner_count
	ifz
	goto	no_pattern	; no pattern, write to preset_x manually

	movlw	0
	decf	inner_count,f
	ifz
	goto	pattern_inc	; =1 simple binary counting



	



;-------------------------------
patmac	macro	patx
	local	nopatx,again
	decf	inner_count,f
	ifnz
	goto	nopatx		; not that pattern
again
	movf	pat_count,w
	call	patx		; read from lookup table
	movwf	tempw
	btfsc	tempw,7
	clrf	pat_count
	btfsc	tempw,7
	goto	again
	incf	pat_count,f
	btfsc	flag,1
	movwf	preset_b
	btfsc	flag,0
	movwf	preset_a
	goto	no_pattern
nopatx
	endm
;--------------------------------
	patmac	pat2
	patmac	pat3
	patmac	pat4
	patmac	pat5
	patmac	pat6
	patmac	pat7
	patmac	pat8
	patmac	pat9
	patmac	pat10
	patmac	pat11
	goto	no_pattern
pattern_inc			; simple binary counting
	btfsc	flag,1
	incf	preset_b,f	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	btfsc	flag,0
	incf	preset_a,f	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
no_pattern			; no pattern, write to [preset_x] manually
	wide_b	0
	wide_b	1
	wide_b	2
	wide_b	3
	wide_b	4
	wide_b	5
	wide_a	0
	wide_a	1
	wide_a	2
rough
; [slow:9] is linearized and written to [count:9]

	copy_b	0		; [slow] ---linearize---> [count]
	copy_b	1
	copy_b	2
	copy_b	3
	copy_b	4
	copy_b	5
	copy_a	0
	copy_a	1
	copy_a	2

; inner loop #3: (executed 256 times)
; at evety pass, all LEDs will first go ON
; and, when some of [count:9] registers reaches zero, that LED will be switched off

	clrf	inner_count
	movlw	0x3f
	movwf	outb		; all LEDs on
	movlw	0x07	
	movwf	outa		; all LEDs on
go_inner			; inner loop
	dec_b	0		; decrement [count], LED off if [count]=0
	dec_b	1		;
	dec_b	2		;
	dec_b	3		;
	dec_b	4		;
	dec_b	5		;
	dec_a	0		;
	dec_a	1		;
	dec_a	2		;
	decfsz	inner_count	;
	goto	go_inner	; inner loop, 30t=5us (256 x 5us = 1.3 ms)

	goto	farm		; main loop (infinite)



	END
