

Draw_Radar:

; TODO - only the radius calculation is changing, so just determine the direction/size of final shift.

				move.w	Draw_MapZoomLevel_w,d0
				and.b	#7,d0
				move.w	.jump(pc,d0.w*2),d0
				jmp		.jump(pc,d0.w)
.jump:
				dc.w	.level_0-.jump
				dc.w	.level_1-.jump
				dc.w	.level_2-.jump
				dc.w	.level_3-.jump
				dc.w	.level_4-.jump
				dc.w	.level_5-.jump
				dc.w	.level_6-.jump
				dc.w	.level_7-.jump
.level_2:
				move.l Sys_FrameNumber_l,d0
				and.w  #$1f,d0 ; every 31 frames
				move.w d0,d2
				move.w d0,d3
				lsr.w  #1,d3
				add.w  #16,d3
				lsl.w  #2,d2
				sub.w  d0,d2
				lsl.w  #1,d2  ; radius in steps of 6

				move.w #160,d0
				move.w #120,d1



				bra Draw_CircleShaded

.level_3:
				move.l Sys_FrameNumber_l,d0
				and.w  #$1f,d0 ; every 31 frames
				move.w d0,d2
				move.w d0,d3
				lsr.w  #1,d3
				add.w  #16,d3
				lsl.w  #2,d2
				sub.w  d0,d2  ; radius in steps of 3

				;move.w #160,d0
				;move.w #120,d1

				;move.w	draw_MapXOffset_w,d0
				;move.w	draw_MapZOffset_w,d1

				; this is almost right, but x drifts a small amount further than
				; the map origin on screen. Why? Is it off by 320/288 ?

				move.w	draw_MapXOffset_w,d0
				move.w	draw_MapZOffset_w,d1
				neg.w	d1
				asr.w	#3,d0
				asr.w   #3,d1
				add.w	Vid_CentreX_w,d0
				add.w	TOTHEMIDDLE,d1

				bra Draw_CircleShaded

.level_4:
				move.l Sys_FrameNumber_l,d0
				and.w  #$1f,d0
				move.w d0,d2
				move.w d0,d3
				lsr.w  #1,d3
				add.w  #16,d3
				lsl.w  #2,d2
				sub.w  d0,d2
				lsr.w  #1,d2

				move.w #160,d0
				move.w #120,d1

				;move.w	draw_MapXOffset_w,d0
				;move.w	draw_MapZOffset_w,d1

				bra Draw_CircleShaded

.level_5:
				move.l Sys_FrameNumber_l,d0
				and.w  #$1f,d0
				move.w d0,d2
				move.w d0,d3
				lsr.w  #1,d3
				add.w  #16,d3
				lsl.w  #2,d2
				sub.w  d0,d2
				lsr.w  #2,d2

				move.w #160,d0
				move.w #120,d1

				;move.w	draw_MapXOffset_w,d0
				;move.w	draw_MapZOffset_w,d1


				bra Draw_CircleShaded

.level_6:
				move.l Sys_FrameNumber_l,d0
				and.w  #$1f,d0
				move.w d0,d2
				move.w d0,d3
				lsr.w  #1,d3
				add.w  #16,d3
				lsl.w  #2,d2
				sub.w  d0,d2
				lsr.w  #3,d2

				move.w #160,d0
				move.w #120,d1

				;move.w	draw_MapXOffset_w,d0
				;move.w	draw_MapZOffset_w,d1


				bra Draw_CircleShaded
.level_0:
.level_1:

.level_7:
				rts

				include "modules/draw/draw_circle.s"
