
wide_b	macro	pos_b
	clrf	target_b+pos_b		; go 0x00
	btfsc	preset_b,pos_b
	decf	target_b+pos_b,f	; go 0xff
	endm

wide_a	macro	pos_a
	clrf	target_a+pos_a		; go 0x00
	btfsc	preset_a,pos_a
	decf	target_a+pos_a,f	; go 0xff
	endm
;	
chase_b	macro	id_b		; [slow] approach (inc or dec) to [target]
	local	eq1b,gth2b
	movf	target_b+id_b,w
	subwf	slow_b+id_b,w		; set C if slow>=target
	ifz
	goto	eq1b			; if Z then skip all
	ifc
	goto	gth2b
	incf	slow_b+id_b,f		; if NC then incf
	incf	slow_b+id_b,f		; if NC then incf
gth2b
	decf	slow_b+id_b,f		; if C then decf
eq1b
	endm

chase_a	macro	id_a		; [slow] approach (inc or dec) to [target]
	local	eq1a,gth2a
	movf	target_a+id_a,w
	subwf	slow_a+id_a,w		; set C if slow>=target
	ifz
	goto	eq1a			; if Z then skip all
	ifc
	goto	gth2a
	incf	slow_a+id_a,f		; if NC then incf
	incf	slow_a+id_a,f		; if NC then incf
gth2a
	decf	slow_a+id_a,f		; if C then decf
eq1a
	endm
;	
copy_b	macro	byte_b		; [slow] ---> [count]
	ccf
	rrf	slow_b+byte_b,w
	call	gamma2			; linearize w with gamma=2
	movwf	count_b+byte_b		; ready for decrementing
	endm

copy_a	macro	byte_a		; [slow] ---> [count]
	ccf
	rrf	slow_a+byte_a,w
	call	gamma2			; linearize w with gamma=2
	movwf	count_a+byte_a		; ready for decrementing
	endm
;	
dec_b	macro	bit_b		; decrement [count], LED off if [count]=0
	decf	count_b+bit_b,f
	ifz
	bcf	outb,bit_b		; if count_b=0, then LED off
	endm

dec_a	macro	bit_a		; decrement [count], LED off if [count]=0
	decf	count_a+bit_a,f
	ifz
	bcf	outa,bit_a		; if count_a=0, then LED off
	endm
;	

;	system flags

ifz	macro
	btfsc	STATUS,Z
	endm

ifnz	macro
	btfss	STATUS,Z
	endm

ifc	macro
	btfsc	STATUS,C
	endm

ifnc	macro
	btfss	STATUS,C
	endm

ccf	macro
	bcf	STATUS,C
	endm

scf	macro
	bsf	STATUS,C
	endm


