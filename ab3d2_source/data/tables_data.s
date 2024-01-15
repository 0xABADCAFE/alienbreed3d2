			section .data,data

; Statically initialised (non-zero) data
			align 4

MAX_ONE_OVER_N	EQU	511

; sine/cosine << 15, contains two full cycles (720 degrees) over 8192 entries
SinCosTable_vw:		incbin	"bigsine"

SINE_OFS		EQU 0
COSINE_OFS		EQU 2048

; Modulus mask value when doing *address* based calculation, e.g. (a0,dN.w)
SINTAB_MASK_ADR	EQU 8190

; Modulus mask value when doing *index* based calculation, e.g. (a0, dN.w*2)
SINTAB_MASK_IDX	EQU 8191

; Angle modulus (address mask)
AMOD_A			MACRO
				and.w	#SINTAB_MASK_ADR,\1
				ENDM

; Angle modulus (index mask)
AMOD_I			MACRO
				and.w	#SINTAB_MASK_IDX,\1
				ENDM

; stores x/3 and x mod 3 for x=0...660
DivThreeTable_vb:
val				SET		0
				REPT	220
				dc.b	val,0
				dc.b	val,1
				dc.b	val,2
val				SET		val+1
				ENDR
