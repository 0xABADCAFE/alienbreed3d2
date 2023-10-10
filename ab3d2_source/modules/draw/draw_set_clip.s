
; Offset into Lvl_ClipsPtr_l data is in a0

Draw_SetLeftClip:
				move.l	#OnScreen_vl,a1
				move.l	#Rotated_vl,a2
				move.l	Lvl_ConnectTablePtr_l,a3
				move.l	Lvl_PointsPtr_l,a4
				move.w	(a0),d0
				bge.s	.dont_ignore_left

				; move.l #0,(a6)

				bra		.left_not_ok_to_clip

.dont_ignore_left:
				move.w	6(a2,d0*8),d3			; left z val
				bgt.s	.left_clip_infront

				addq	#2,a0
				rts

				tst.w	6(a2,d0*8)
				bgt.s	.left_not_ok_to_clip

.ignore_both:
				; move.l #0,(a6)
				; move.l #96*65536,4(a6)
				move.w	#0,Draw_LeftClip_w
				move.w	Vid_RightX_w,Draw_RightClip_w
				addq	#8,a6
				addq	#2,a0
				rts

.left_clip_infront:
				move.w	(a1,d0*2),d1			; left x on screen
				move.w	(a0),d2
				move.w	2(a3,d2.w*4),d2
				move.w	(a1,d2.w*2),d2
				cmp.w	d1,d2
				bgt.s	.left_not_ok_to_clip

				; move.w d1,(a6)
				; move.w d3,2(a6)
				cmp.w	Draw_LeftClip_w,d1
				ble.s	.left_not_ok_to_clip

				move.w	d1,Draw_LeftClip_w

.left_not_ok_to_clip:
				addq	#2,a0
				rts

Draw_SetRightClip:
				move.l	#OnScreen_vl,a1
				move.l	#Rotated_vl,a2
				move.l	Lvl_ConnectTablePtr_l,a3
				move.w	(a0),d0
				bge.s	.dont_ignore_right

				; move.w #96,4(a6)
				; move.w #0,6(a6)

				move.w	#0,d4
				bra		.right_not_ok_to_clip

.dont_ignore_right:
				move.w	6(a2,d0*8),d4			; right z val
				bgt.s	.right_clip_infront

				; move.w #96,4(a6)
				; move.w #0,6(a6)

				bra.s	.right_not_ok_to_clip

.right_clip_infront:
				move.w	(a1,d0*2),d1			; right x on screen
				move.w	(a0),d2
				move.w	(a3,d2.w*4),d2
				move.w	(a1,d2.w*2),d2
				cmp.w	d1,d2
				blt.s	.right_not_ok_to_clip

				; move.w d1,4(a6)
				; move.w d4,6(a6)

				cmp.w	Draw_RightClip_w,d1
				bge.s	.right_not_ok_to_clip
				addq	#1,d1
				move.w	d1,Draw_RightClip_w

.right_not_ok_to_clip:
				addq	#8,a6
				addq	#2,a0
				rts
