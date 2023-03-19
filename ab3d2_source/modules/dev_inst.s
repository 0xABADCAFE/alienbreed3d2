;
; *****************************************************************************
; *
; * modules/dev_inst.s
; *
; * Developer mode instrumentation
; *
; *****************************************************************************

; DEVMODE INSTRUMENTATION

				IFD	DEV

				section bss,bss
				align 4

dev_GraphBuffer_vb:			ds.b	DEV_GRAPH_BUFFER_SIZE*2 ; array of times
dev_ECVToMsFactor_l:		ds.l	1   ; factor for converting EClock value differences to ms

; EClockVal stamps
dev_ECVFrameBegin_q:		ds.l	2	; timestamp at the start of the frame
dev_ECVDrawDone_q:			ds.l	2	; timestamp at the end of drawing
dev_ECVChunkyDone_q:		ds.l	2	; timestamp at the end of chunky to planar
dev_ECVFrameEnd_q:			ds.l	2	; timestamp at the end of the frame

; FPS Filter
dev_FPSFilter_l:			ds.l	1

; Counters
dev_Counters_vw:
dev_VisibleModelCount_w:	ds.w	1	; visible polygon models this frame
dev_VisibleGlareCount_w:	ds.w	1	; visible glare bitmaps this frame
dev_VisibleLightMapCount_w:	ds.w	1	; visible lightsource bitmaps this frame
dev_VisibleAdditiveCount_w:	ds.w	1	; visible additive bitmaps this frame
dev_VisibleBitmapCount_w:	ds.w	1	; visible bitmaps this fame

dev_TotalCounters_vw:
dev_VisibleObjectCount_w:	ds.w	1	; total visible objects this frame (total )
dev_DrawObjectCallCount_w:	ds.w	1	; Number of calls to Draw_Object
dev_DrawTimeMsAvg_w:		ds.w	1   ; two frame average of draw time

dev_FPSIntAvg_w:			ds.w	1
dev_FPSFracAvg_w:			ds.w	1
dev_FrameIndex_w:			ds.w	1	; frame number % DEV_GRAPH_BUFFER_SIZE
dev_Reserved_w:				ds.w	1


; Character buffer for printing
dev_CharBuffer_vb:	dcb.b	64

				section code,code
				align 4

;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

; Initialise the developer options
Dev_Init:
				lea		timername,a0
				lea		timerrequest,a1
				moveq	#0,d0
				moveq	#0,d1
				CALLEXEC OpenDevice

				move.l	timerrequest+IO_DEVICE,_TimerBase
				move.l	d0,timerflag

				; Grab the EClockRate
				lea		dev_ECVFrameBegin_q,a0
				jsr		Dev_TimeStamp

				; Convert eclock rate to scale factor that we will first multiply by, then divide by 65536
				move.l	#65536000,d1
				divu.l	d0,d1
				move.l	d1,dev_ECVToMsFactor_l
				rts

Dev_DataReset:
				lea		dev_GraphBuffer_vb,a0
				move.l	#(DEV_GRAPH_BUFFER_SIZE/16)-1,d0
.loop:
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				dbra	d0,.loop
				clr.w	dev_DrawTimeMsAvg_w
				rts

;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

; Subtract two timestamps, First pointed to by a0, second by a1. Full return in d1 (upper) : d0(lower)
; Generally we don't care about the upper, but it's calculated in case we want it.
dev_Elapsed:
				move.l	d2,-(sp)
				move.l	(a1),d1
				move.l	4(a1),d0
				move.l	(a0),d2
				sub.l	4(a0),d0
				subx.l	d2,d1
				move.l	(sp)+,d2
				rts

;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

; Generic timestamp, uses EClockVal in a0
Dev_TimeStamp:
				move.l	a6,-(sp)
				move.l	_TimerBase,a6
				jsr		_LVOReadEClock(a6)
				move.l	(sp)+,a6
				rts

; Mark the beginning of a new frame.
Dev_MarkFrameBegin:
				move.w	dev_FrameIndex_w,d0
				addq.w	#1,d0
				and.w	#DEV_GRAPH_BUFFER_MASK,d0
				move.w	d0,dev_FrameIndex_w
				lea		dev_Counters_vw,a0
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				clr.l	(a0)+
				lea		dev_ECVFrameBegin_q,a0
				bra.s	Dev_TimeStamp

; Mark the end of drawing
Dev_MarkDrawDone:
				; sum up the different rendered object types this frame
				lea		dev_Counters_vw,a0
				clr.l	d0
				add.w	(a0)+,d0
				add.w	(a0)+,d0
				add.w	(a0)+,d0
				add.w	(a0)+,d0
				add.w	(a0)+,d0
				move.w	d0,dev_VisibleObjectCount_w
				lea		dev_ECVDrawDone_q,a0
				bra.s	Dev_TimeStamp

; Mark the end of chunky conversion / copy
Dev_MarkChunkyDone:
				lea		dev_ECVChunkyDone_q,a0
				bra.s	Dev_TimeStamp

; Mark the end of the frame
Dev_MarkFrameEnd:
				lea		dev_ECVFrameEnd_q,a0
				bra.s	Dev_TimeStamp

; Basic printf() type functionality based on exec/RawDoFmt(). Keep the data size shorter than dev_CharBuffer_vb
; or expect overflow.
; d0: coordinate pair (x16:y16)
; a0: format template
; a1: data stream

Dev_PrintF:
				movem.l		d2/a2/a3/a6,-(sp)
				move.l		d0,d2					; coordinate pair
				move.w		#0,.dev_Length
				lea			.dev_PutChar(pc),a2
				lea			dev_CharBuffer_vb,a3
				CALLEXEC	RawDoFmt				; Format into dev_CharBuffer_vb

				move.l		Vid_MainScreen_l,a1
				lea			sc_RastPort(a1),a1
				clr.l		d1
				move.w		d2,d1 ; d1: y coordinate
				clr.l		d0
				swap		d2
				move.w		d2,d0 ; d0: x coordinate
				CALLGRAF 	Move

				move.w		.dev_Length(pc),d0
				subq		#1,d0
				lea			dev_CharBuffer_vb,a0
				jsr			_LVOText(a6)

				movem.l		(sp)+,d2/a2/a3/a6
				rts

.dev_Length:
				dc.w 0		; tracks characters written by the following stuffer
.dev_PutChar:
				move.b			d0,(a3)+
				add.w			#1,.dev_Length
				rts

;
Dev_PrintStats:
				lea				dev_ECVFrameBegin_q,a0
				lea				dev_ECVFrameEnd_q,a1
				bsr				dev_ECVDiffToMs

				add.l			dev_FPSFilter_l,d0				; Average with previous ms value
				lsr.l			#1,d0							; Todo, average over longer duration
				move.l			d0,dev_FPSFilter_l				; Update
				move.l			#10000,d1
				divu.l			d0,d1							; frames per 10 seconds
				divu.w			#10,d1							; decimate, remainder contains 1/10th seconds
				swap			d1								;
				move.l			d1,dev_FPSIntAvg_w				; Shove it out

				tst.b			Vid_FullScreen_b
				bne.s			.fullscreen_stats

				; smallscreen
				lea				dev_TotalCounters_vw,a1
				lea				.dev_ss_stats_obj_vb,a0
				move.l			#8,d0
				bsr				Dev_PrintF

				; Polygon objects
				lea				dev_VisibleModelCount_w,a1
				lea				.dev_ss_stats_obj_poly_vb,a0
				move.l			#24,d0
				bsr				Dev_PrintF

				; Glare objects
				lea				dev_VisibleGlareCount_w,a1
				lea				.dev_ss_stats_obj_glare_vb,a0
				move.l			#40,d0
				bsr				Dev_PrintF

				; Lightmap bitmap objects
				lea				dev_VisibleLightMapCount_w,a1
				lea				.dev_ss_stats_obj_lightmap_vb,a0
				move.l			#56,d0
				bsr				Dev_PrintF

				; Additive bitmap objects
				lea				dev_VisibleAdditiveCount_w,a1
				lea				.dev_ss_stats_obj_additive_vb,a0
				move.l			#72,d0
				bsr				Dev_PrintF

				; Vanilla bitmap objects
				lea				dev_VisibleBitmapCount_w,a1
				lea				.dev_ss_stats_obj_bitmap_vb,a0
				move.l			#88,d0
				bsr				Dev_PrintF
				rts

.fullscreen_stats:
				lea				dev_TotalCounters_vw,a1
				lea				.dev_fs_stats_tpl_vb,a0
				move.l			#(SCREEN_WIDTH/2)<<16|(SCREEN_HEIGHT-24),d0
				bra				Dev_PrintF

.dev_fs_stats_tpl_vb:
				dc.b			"O:%2d/%2d D:%2dms %2d.%dfps",0

.dev_ss_stats_obj_vb:
				dc.b			"Objs:%2d/%2d, Draw:%2dms, %2d.%dfps",0
.dev_ss_stats_obj_poly_vb:
				dc.b			"P:%2d",0
.dev_ss_stats_obj_glare_vb:
				dc.b			"G:%2d",0
.dev_ss_stats_obj_lightmap_vb:
				dc.b			"L:%2d",0
.dev_ss_stats_obj_additive_vb:
				dc.b			"A:%2d",0
.dev_ss_stats_obj_bitmap_vb:
				dc.b			"B:%2d",0

				align 4

;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

; Calculate the difference between a pair of ECV timestamps to milliseconds. Return is 16 bit.
; Start timestamp pointed to by a0
; End timestamp pointed to by a1
; return ms in d0
dev_ECVDiffToMs:
				move.l	4(a1),d0
				sub.l	4(a0),d0
				mulu.l	dev_ECVToMsFactor_l,d0
				clr.w	d0
				swap	d0
				rts


; Calculate the times and store in the graph data buffer
Dev_DrawGraph:
				move.l	d2,-(sp)
				lea		dev_ECVFrameBegin_q,a0
				lea		dev_ECVDrawDone_q,a1
				bsr.s	dev_ECVDiffToMs
				lea		dev_GraphBuffer_vb,a0			; Put the ms value into the graph buffer
				move.w	dev_FrameIndex_w,d1
				add.w	dev_DrawTimeMsAvg_w,d0
				lsr.w	#1,d0
				move.w	d0,dev_DrawTimeMsAvg_w
				lsr.b	#1,d0
				move.b	d0,(a0,d1.w*2)
				move.b	dev_VisibleObjectCount_w+1,1(a0,d1.w*2)

				; Now draw it...
				move.l	Vid_FastBufferPtr_l,a0

				; In fullscreen, we need to make a small adjustment
				IFNE	FS_HEIGHT_C2P_DIFF
				moveq	#FS_HEIGHT_C2P_DIFF,d2
				and.b	Vid_FullScreen_b,d2
				ENDC

				move.w	Vid_BottomY_w,d0
				sub.w	d2,d0

				sub.w	Vid_LetterBoxMarginHeight_w,d0
				mulu.w	#SCREEN_WIDTH,d0
				add.l	d0,a0 							; a0 points at lower left of render area
				lea		dev_GraphBuffer_vb,a1

				; draw buffer position should be one ahead of the write position.
				addq.w	#1,d1
				and.w	#DEV_GRAPH_BUFFER_MASK,d1

				; Draw loop
				move.l	#DEV_GRAPH_BUFFER_SIZE-1,d0
.loop:
				; plot draw time average
				clr.l	d2
				move.b	(a1,d1.w*2),d2
				lsr.b	#1,d2 ; restrict the maximum deflection
				muls.w	#-SCREEN_WIDTH,d2
				move.b	#DEV_GRAPH_DRAW_TIME_COLOUR,(a0,d2)

				; plot object count
				clr.l	d2
				move.b	1(a1,d1.w*2),d2
				muls.w	#-SCREEN_WIDTH,d2
				move.b	#31,(a0,d2)

				addq.l	#1,d1
				and.l	#DEV_GRAPH_BUFFER_MASK,d1
				addq.l	#1,a0
				dbra	d0,.loop

				move.l	(sp)+,d2
				rts

timerrequest:				ds.b	IOTV_SIZE
timername:					dc.b	"timer.device",0

				align	4
_TimerBase:		dc.l	0
timerflag:		dc.l	-1

				ENDC
