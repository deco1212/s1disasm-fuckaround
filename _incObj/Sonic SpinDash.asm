; ---------------------------------------------------------------------------
; Subroutine to check for starting to charge a spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


Sonic_SpinDash:
		tst.b	spindash_flag(a0)	; is Sonic already Spin Dashing?
		bne.s	Sonic_UpdateSpindash	; if yes, branch to updating spin dash
		cmpi.b	#id_Duck,obAnim(a0)
		bne.s	.return			; if not ducking down, return
		move.b	(v_jpadpress2).w,d0
		andi.b	#btnB|btnC|btnA,d0
		beq.w	.return			; if not pressing ABC, return
		move.b	#id_Roll,obAnim(a0)	; ***temporary anim***
		move.w	#sfx_Roll,d0		; ***temporary sfx***
		jsr	(PlaySound_Special).l
		addq.l	#4,sp
		move.b	#1,spindash_flag(a0)
		move.w	#0,spindash_counter(a0)
		cmpi.b	#12,obSubtype(a0)	; if he's drowning, branch to not make dust
		blo.s	.nodust
		move.b	#2,(v_spindust+obAnim).w

	.nodust:
		bsr.w	Sonic_LevelBound
		bra.w	Sonic_AnglePos

	.return:
		rts
; End of function Sonic_SpinDash


; ---------------------------------------------------------------------------
; Subroutine to update an already-charging spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


Sonic_UpdateSpindash:
		move.b	#id_Roll,obAnim(a0)	; ***temporary anim***
		move.b	(v_jpadhold2).w,d0 
		btst	#bitDn,d0
		bne.w	Sonic_ChargingSpindash

		; unleash the charged spindash and start rolling quickly:
		move.b	#$E,obHeight(a0)
		move.b	#7,obWidth(a0)
		move.b	#id_Roll,obAnim(a0)
		addq.w	#5,obY(a0)	; add the difference between Sonic's rolling and standing heights
		move.b	#0,spindash_flag(a0)
		moveq	#0,d0
		move.b	spindash_counter(a0),d0
		add.w	d0,d0
		move.w	SpindashSpeeds(pc,d0.w),obInertia(a0)

		; Determine how long to lag the camera for.
		; Notably, the faster Sonic goes, the less the camera lags.
		; This is seemingly to prevent Sonic from going off-screen.
		move.b	obInertia(a0),d0
		subq.b	#8,d0			; $800 is the lowest spin dash speed
		add.b	d0,d0
		andi.b	#$1F,d0
		neg.w	d0
		addi.b	#$20,d0
		move.b	d0,($FFFFEED0).w	; camera lag value in RAM

		btst	#0,obStatus(a0)		; is Sonic facing left?
		beq.s	.dontflip		; if not, branch
		neg.w	obInertia(a0)

.dontflip:
		bset	#2,obStatus(a0)
		move.b	#0,(v_spindust+obAnim).w 
		move.w	#sfx_Teleport,d0	; spindash zoom sound
		jsr	(PlaySound_Special).l 
		bra.s	Sonic_Spindash_ResetScr
; ===========================================================================
SpindashSpeeds:
		dc.w  $800	; 0
		dc.w  $880	; 1
		dc.w  $900	; 2
		dc.w  $980	; 3
		dc.w  $A00	; 4
		dc.w  $A80	; 5
		dc.w  $B00	; 6
		dc.w  $B80	; 7
		dc.w  $C00	; 8
; ===========================================================================

Sonic_ChargingSpindash:			; If still charging the dash...
		tst.w	spindash_counter(a0)
		beq.s	.chkInput
		move.w	spindash_counter(a0),d0
		lsr.w	#5,d0
		sub.w	d0,spindash_counter(a0)		; SpinDash rev down effect applied
		bcc.s	.chkInput
		move.w	#0,spindash_counter(a0)

	.chkInput:
		move.b	(v_jpadpress2).w,d0 
		andi.b	#btnB|btnC|btnA,d0
		beq.w	Sonic_Spindash_ResetScr
		move.w	#(id_Roll<<8)|(id_Walk<<0),obAnim(a0)	; ***temporary anim***
		move.w	#sfx_Roll,d0				; ***temporary sfx***
		jsr	(PlaySound_Special).l
		addi.w	#$200,spindash_counter(a0)
		cmpi.w	#$800,spindash_counter(a0)
		blo.s	Sonic_Spindash_ResetScr
		move.w	#$800,spindash_counter(a0)

Sonic_Spindash_ResetScr:
		addq.l	#4,sp
		cmpi.w	#$60,(v_lookshift).w
		beq.s	loc_1AD8C
		bhs.s	+
		addq.w	#4,(v_lookshift).w

+
		subq.w	#2,(v_lookshift).w

loc_1AD8C:
		bsr.w	Sonic_LevelBound
		bra.w	Sonic_AnglePos