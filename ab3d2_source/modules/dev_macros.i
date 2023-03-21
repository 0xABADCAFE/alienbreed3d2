;
; *****************************************************************************
; *
; * modules/dev_macros.i
; *
; * Developer mode instrumentation
; *
; *****************************************************************************

; DEVMODE INSTRUMENTATION MACROS

DEV_SKIP_FLATS					EQU 0
DEV_SKIP_SIMPLE_WALLS			EQU 1
DEV_SKIP_SHADED_WALLS			EQU 2
DEV_SKIP_BITMAPS				EQU 3
DEV_SKIP_GLARE_BITMAPS			EQU 4
DEV_SKIP_ADDITIVE_BITMAPS		EQU 5
DEV_SKIP_LIGHTSOURCED_BITMAPS	EQU 6
DEV_SKIP_POLYGON_MODELS			EQU 7

; When any of the level geometry is skipped, we need to make sure the fast buffer gets cleared
DEV_CLEAR_FASTBUFFER_MASK		EQU (1<<DEV_SKIP_FLATS)|(1<<DEV_SKIP_SIMPLE_WALLS)|(1<<DEV_SKIP_SHADED_WALLS)

				IFD	DEV

DEV_GRAPH_BUFFER_DIM 			EQU 6
DEV_GRAPH_BUFFER_SIZE 			EQU 64
DEV_GRAPH_BUFFER_MASK 			EQU 63
DEV_GRAPH_DRAW_TIME_COLOUR		EQU 255
DEV_GRAPH_OBJECT_COUNT_COLOUR	EQU 31

; Macro to call a developer method.
CALLDEV			MACRO
				jsr	Dev_\1
				ENDM

; Macros for increasing/decreasing a dev counter. The ability to decrease is included to allow for simpler injection
; points where it's easier to increment on entry to something and decrement in some common early out.
; Example uses:
;				DEV_INC.w	VisibleFlats - calling on an entry to floor drawing
;				DEV_DEC.w	VisibleFlats - calling in early out of floor drawing

DEV_INC			MACRO
				addq.\0	#1,dev_\1_\0
				ENDM

DEV_DEC			MACRO
				subq.\0	#1,dev_\1_\0
				ENDM

; Macros for saving register state.
DEV_SAVE		MACRO
				movem.l	\1,-(sp)
				ENDM

DEV_RESTORE		MACRO
				movem.l	(sp)+,\1
				ENDM

; Macro for conditionally skipping code based on a devmode flag. Unfortunately there's no btst.l #<im>,<ea> for
; non data-register ea modes. So we calculate a byte offset as well as the bit position in that byte.
DEV_CHECK		MACRO
				btst.b	#(DEV_SKIP_\1)&7,dev_SkipFlags_l+3-(DEV_SKIP_\1>>3)
				bne		\2
				ENDM


; For the release build, all the macros are empty and no code is generated.
				ELSE

CALLDEV			MACRO
				ENDM

DEV_ELAPSED32	MACRO
				ENDM

DEV_INC			MACRO
				ENDM

DEV_DEC			MACRO
				ENDM

DEV_SAVE		MACRO
				ENDM

DEV_RESTORE		MACRO
				ENDM

DEV_CHECK		MACRO
				ENDM

				ENDC
