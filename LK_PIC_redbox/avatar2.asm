
		include "p16c5x.inc"

;*
;* Sutekh Avatar Version 2.x
;*

;* re-entered for MPLAB fixed bugs in early version

;* February 2026

;* device is Microchip PCI16C54-XT/P
;* digikey PIC16C54-XT/P-ND
;*
;*		equates
;*

;
; registers
;

buttons	= 0x05	; buttons on porta
dac		= 0x06	; dac is portb

t1c_hi	= 0x08		; tone constants
t1c_lo	= 0x09
t2c_hi	= 0x0a
t2c_lo	= 0x0b

dur_hi	= 0x0c	; tone duration registers
dur_lo	= 0x0d

ph1_hi	= 0x0e	; phase accumulation registers
ph1_lo  = 0x0f
ph2_hi	= 0x10
ph2_lo	= 0x11

pwreg0	= 0x12	; circulating pw registers
pwreg1	= 0x13
pwreg2	= 0x14
pwreg3	= 0x15

pulse	= 0x16
secure	= 0x17
digit	= 0x18

temp	= 0x1e
scratch = 0x1f


;
; constants
;

pass3	= 0x11
pass2	= 0x22
pass1	= 0x21
pass0	= 0x21

; sine table
;
; this sine table is calculated for use with
; an emitter follower amplifier
;
; the table includes a dc offset to insure that
; there will be no clipping of the wave
;

sine0	= 0x4c	;	76
sine1	= 0x5f	;	95
sine2	= 0x6f	;	111
sine3	= 0x7a	;	122
sine4	= 0x7f	;	127
sine5	= 0x7a	;	122
sine6	= 0x6f	;	111
sine7	= 0x5f	;	95
sine8	= 0x4c	;	76
sine9	= 0x39	;	57
sine10	= 0x29	;	41
sine11	= 0x1e	;	30
sine12	= 0x1a	;	26
sine13  = 0x1e	;	30
sine14	= 0x29	;	41
sine15	= 0x39	;	57

secval	= 0xA5
nil		= 0

red1_hi	= 0x016
red1_lo	= 0x0DB
red2_hi	= 0x01D
red2_lo = 0x094

dtmf770_hi = 0x0a
dtmf770_lo = 0x5a
dtmf1209_hi = 0x10
dtmf1209_lo = 0x41
dtmf1336_hi = 0x11
dtmf1336_lo = 0xf6

ahi		= 0x05
alo		= 0xea
chi		= 0x1b
clo		= 0x89
ehi		= 0x22
elo		= 0x6c
ghi		= 0x29
glo		= 0x4e

_15mshi	= 0x02
_15mslo	= 0x1e
_33mshi	= 0x03
_33mslo	= 0x74
_66mshi	= 0x05
_66mslo	= 0xe8
_500mslo = 0x26
_500mshi = 0x27
_2sechi	= 0x95
_2seclo = 0xc0

			org 1FFH
reset:		goto wake_up

			org	0
			sleep

twotone:	nop		; generate two tones (loop time = 47 cycles)
			nop		; at Fosc 3.579545 Hz T=52.520641 uS

tt:			clrwdt

			movf	t1c_lo, w	; advance phase for tone 1
			addwf	ph1_lo, f
			movf	t1c_hi, w
			btfsc	STATUS, C
			incf	t1c_hi, w
			addwf	ph1_hi, f
		
			movf	t2c_lo, w	; advance phase fpr tone 2
			addwf	ph2_lo, f
			movf	t2c_hi, w
			btfsc	STATUS, C
			incf	t2c_hi, w
			addwf	ph2_hi, f

			movf	ph1_hi, w	; look up amplitudes
			call	ph2sin
			movwf	scratch
			movf	ph2_hi, w
			call	ph2sin
			addwf	scratch, w	; sum waves
			movwf	dac			; ship to dac
			
			decfsz	dur_lo, f
			goto	twotone
			decfsz	dur_hi, f
			goto	tt			; jump short to make loop time consistent
			retlw	nil

ph2sin:		movwf	temp
			swapf	temp, w
			andlw	#0FH
			movwf	temp
			movlw	table
			addwf	temp, w
			movwf	PCL			; computed goto

table:		retlw	sine0
			retlw	sine1
			retlw	sine2
			retlw	sine3
			retlw	sine4
			retlw	sine5
			retlw	sine6
			retlw	sine7
			retlw	sine8
			retlw	sine9
			retlw	sine10
			retlw	sine11
			retlw	sine12
			retlw	sine13
			retlw	sine14
			retlw	sine15

; setup for musical A standard pitch 
su_A:		movlw	ahi
			movwf	t1c_hi
			movlw	alo
			movwf	t1c_lo
			clrf	t2c_hi	; single tone
			clrf	t2c_lo
			retlw	nil

; setup for musical C standard pitch 
su_C:		movlw	chi
			movwf	t1c_hi
			movlw	clo
			movwf	t1c_lo
			clrf	t2c_hi	; single tone
			clrf	t2c_lo
			retlw	nil

; setup for musical E standard pitch 
su_E:		movlw	ehi
			movwf	t1c_hi
			movlw	elo
			movwf	t1c_lo
			clrf	t2c_hi	; single tone
			clrf	t2c_lo
			retlw	nil

; setup for musical E standard pitch 
su_G:		movlw	ghi
			movwf	t1c_hi
			movlw	glo
			movwf	t1c_lo
			clrf	t2c_hi	; single tone
			clrf	t2c_lo
			retlw	nil


; setup for major third interval
su_3rd:		movlw	chi
			movwf	t1c_hi
			movlw	clo
			movwf	t1c_lo
			movlw	ehi
			movwf	t2c_hi
			movlw	elo
			movwf	t2c_lo
			retlw	nil

; setup for major third interval
su_5th:		movlw	chi
			movwf	t1c_hi
			movlw	clo
			movwf	t1c_lo
			movlw	ghi
			movwf	t2c_hi
			movlw	glo
			movwf	t2c_lo
			retlw	nil

			sleep

su_red:		movlw	red1_hi
			movwf	t1c_hi
			movlw	red1_lo
			movwf	t1c_lo
			movlw	red2_hi
			movwf	t2c_hi
			movlw	red2_lo
			movwf	t2c_lo
			retlw	nil			

su_dtmf4:	movlw	dtmf770_hi
			movwf	t1c_hi
			movlw	dtmf770_lo
			movwf	t1c_lo
			movlw	dtmf1209_hi
			movwf	t2c_hi
			movlw	dtmf1209_lo
			movwf	t2c_lo
			retlw	nil		

su_dtmf5:	movlw	dtmf770_hi
			movwf	t1c_hi
			movlw	dtmf770_lo
			movwf	t1c_lo
			movlw	dtmf1336_hi
			movwf	t2c_hi
			movlw	dtmf1336_lo
			movwf	t2c_lo
			retlw	nil		

su_wait:	clrf	t1c_hi
			clrf	t1c_lo
			clrf	t2c_hi
			clrf	t2c_lo
			retlw	nil

do_15:		movlw	_15mshi
			movwf	dur_hi
			movlw	_15mslo
			movwf	dur_lo
			goto	twotone

do_33:		movlw	_33mshi
			movwf	dur_hi
			movlw	_33mslo
			movwf	dur_lo
			goto	twotone

do_66:		movlw	_66mshi
			movwf	dur_hi
			movlw	_66mslo
			movwf	dur_lo
			goto	twotone

do_500:		movlw	_500mshi
			movwf	dur_hi
			movlw	_500mslo
			movwf	dur_lo
			goto	twotone

do_2sec:	movlw	_2sechi
			movwf	dur_hi
			movlw	_2seclo
			movwf	dur_lo
			goto	twotone

wake_up:
			clrw
			option

			btfsc	PORTA,2
			goto	test1
			btfsc	PORTA,3
			goto	test2

			movf	secure, w
			xorlw	secval
			btfsc	STATUS, Z
			goto	armed

unarmed:	btfsc	PORTA, 0
			goto	bump
			btfsc	PORTA, 1
			goto	enter
			sleep

bump:		incf	digit, f
			clrw
			tris	dac
			call 	su_dtmf4
			call	do_66
			call	su_wait
			call 	do_66
			sleep
	
enter:		movlw	4
			movwf	temp
r1:			rlf		pwreg0, f
			rlf		pwreg1, f
			rlf		pwreg2, f
			rlf		pwreg3, f
			decfsz	temp, f
			goto	r1

			movf	pwreg0, w
			andlw	0xf0
			iorwf	digit, w
			movwf	pwreg0
			clrf	digit

			clrw
			tris	dac		

chkpw:		movlw	4
			movwf	temp
			
			movf	pwreg0, w
			xorlw	pass0
			btfsc	STATUS, Z
			decf	temp, f

			movf	pwreg1, w
			xorlw	pass1
			btfsc	STATUS, Z
			decf	temp, f 

			movf	pwreg2, w
			xorlw	pass2
			btfsc	STATUS, Z
			decf	temp, f

			movf	pwreg3, w
			xorlw	pass3
			btfsc	STATUS, Z
			decf	temp, f

            btfss	STATUS, Z
			goto	noway
			goto	arm

noway:		clrf	secure
			call	su_dtmf5
			call	do_66
			call	su_wait
			call 	do_66
			sleep

arm:		movlw	secval
			movwf	secure
			call	su_C
			call	do_66
			call	su_wait
			call	do_66
			call	su_E
			call	do_66
			call	su_wait
			call	do_66
			call	su_G
			call	do_66
			sleep

armed:		movf	PORTA, W
			xorlw	0x03		; both buttons down?
			btfsc	STATUS, Z
			goto	disarm

			btfsc	PORTA, 0
			goto	quarter
			btfsc	PORTA, 1
			goto	dime
			sleep

disarm:		clrf	secure
			clrf	pwreg0
			clrf	pwreg1
			clrf	pwreg2
			clrf	pwreg3
			clrf	digit
			call	su_A
			call	do_66
			sleep

test1:		clrw
			tris	dac
			call	su_A
t1:			call	do_2sec
			goto	t1

test2:		clrwdt
			clrw
			tris	dac
			incf	temp, f
			movf	temp, w
			movwf	dac
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			goto	test2

			sleep				; stop any fall thru

quarter:	clrw
			tris	dac
			movlw	5
			movwf	pulse
qloop:		call	su_red
			call	do_33
			call	su_wait
			call	do_33
			decfsz	pulse, f
			goto	qloop
			call	do_500
			sleep

dime:		clrw
			tris	dac
			movlw	2
			movwf	pulse
dloop:		call	su_red
			call	do_66
			call	su_wait
			call	do_66
			decfsz	pulse, f
			goto	dloop		
			call	do_500
			sleep	


;;;;;;;;;;;;;;;;;;;;
		end

