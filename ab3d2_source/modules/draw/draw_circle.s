

; Params
; d0.w centreX
; d1.w centreY
; d2.w radius
; d3.w shade (0 - 31 white to normal, 32-63 normal to black)
; param registers are not preserved.

Draw_CircleShaded:
				tst.w   d2
				bgt.s   .check_big

.early_exit:
				rts

.check_big:
				; nope
				cmp.w   #512,d2
				bge.s   .early_exit

.decide_path:
				;if (
				;   x - radius >= 0 && x + radius < Vid_RightX_w &&
				;   y - radius >= 0 && y + radius < Vid_BottomY_w
				;)

				swap    d3 ; use upper half for arithmetic temporary

.check_inside_left:
				move.w  d0,d3
				sub.w   d2,d3 ; x - radius
				blt.s   .not_inside

.check_inside_right:
				move.w  d0,d3
				add.w   d2,d3    ; x + radius
				cmp.w   Vid_RightX_w,d3 ; x + radius
				bge.s   .not_inside

.check_inside_top:
				move.w  d1,d3
				sub.w   d2,d3   ; y - radius
				blt.s   .not_inside

.check_inside_bottom:
				move.w  d1,d3
				add.w   d2,d3
				cmp.w   Vid_BottomY_w,d3
				bge.s   .not_inside

				; We are fully inside the view rectangle, no clipping needed.
.fully_inside:
				; restore shadeval
				swap   d3
				bra.s  draw_ShadeCircleUnclipped

				; We are not fully inside the view rectangle so we need to ensrure
				; we aren't completely outside it either before we go down the
				; clipping path.
.not_inside:
				;else if (
				;    x + radius >= 0 && x - radius <= Vid_RightX_w &&
				;    y + radius >= 0 && y - radius <= Vid_BottomY_w
				;)

.check_left:
				move.w  d0,d3
				add.w   d2,d3 ; x + radius
				blt.s   .fully_outside

.check_right:
				move.w  d0,d3
				sub.w   d2,d3
				cmp.w   Vid_RightX_w,d3 ; x - radius
				bge.s   .fully_outside

.check_top:
				move.w  d1,d3
				add.w   d2,d3   ; y + radius
				blt.s   .fully_outside

.check_bottom:
				move.w  d1,d3
				add.w   d2,d3 ; y - radius
				cmp.w   Vid_BottomY_w,d3
				bge.s   .fully_outside:


OUTCODE_POS_LEFT	EQU 0
OUTCODE_POS_RIGHT	EQU 1
OUTCODE_POS_TOP		EQU 2
OUTCODE_POS_BOTTOM	EQU 3
OUTCODE_BIT_LEFT	EQU 1<<OUTCODE_POS_LEFT
OUTCODE_BIT_RIGHT	EQU 1<<OUTCODE_POS_RIGHT
OUTCODE_BIT_TOP		EQU 1<<OUTCODE_POS_TOP
OUTCODE_BIT_BOTTOM	EQU 1<<OUTCODE_POS_BOTTOM


.clipped:
				; Determine where the centre of the circle is. We can use Sutherland-Cohen style
				; outcode calculation here.

				; shade level is still in upper word.
				clr.w   d3

				; Test X
				tst.w   d0
				bpl.s   .not_left
				bset    #OUTCODE_POS_LEFT,d3
.not_left:
				cmp.w   Vid_RightX_w,d0
				blt.s   .not_right
				bset    #OUTCODE_POS_RIGHT,d3
.not_right:
				tst.w   d1
				bpl.s   .not_top
				bset    #OUTCODE_POS_TOP,d3
.not_top:
				cmp.w   Vid_BottomY_w,d3
				blt.s   .not_bottom
				bset    #OUTCODE_POS_BOTTOM,d3
.not_bottom:

				; Outcode in d3


				swap d3

.fully_outside:
				swap d3
				rts




; Plotting macros. In order to validate each pixel is plotted once, define VALIDATE_PIXEL_ONCE
; which chages the plotting mode to a straight increment. Test against a flat background shade.

				IFD VALIDATE_PIXEL_ONCE
PLOT			MACRO
				add.b #32,\2 ; Increment the buffer
				ENDM
				ELSE
PLOT			MACRO
				move.b  \1,\2 ; Write value to the buffer
				ENDM
				ENDIF


; Unclipped Circle Routine : Rewritten from compiler output
;
; Uses Jesko Midpoint algorithm to plot 8 octants per loop. Results are
; undefied and potentially disasterous if the circle position/size exceed
; the buffer extents. This code should only be used when the circle is
; already guaranteed to fit within the render buffer.
;
; Octants
;
;    \F | G/
;     \ | /
;   E  \|/  H
; ------o------
;   D  /|\  A
;     / | \
;    /C | B\
;
; Points are plotted as luminance over the buffer by first reading the pixel
; then looking up it's luminance remapepd value in the slice of the shade
; table indicated by the shade value.
;
; This is a total refactor of the compiler generated baseline that aims to
; pair octant read/remap/write cycles to avoid AGU stalls. The main loop is
; free from stride table reads and multiplication.
;
; Params
; d0.w centreX
; d1.w centreY
; d2.w radius
; d3.w shade (0 - 31 white to normal, 32-63 normal to black)

draw_ShadeCircleUnclipped:
				cmp.w	#16,d2
				bge.s	.ready

.small_path:
				movem.l	a2-a4,-(sp)
				; shade table lookup
				and.l   #$3f,d3
				lsl.l   #8,d3                              ; 256 bytes per slice
				add.l   Draw_PaletteShadeTablePtr_l,d3
				move.l  d3,a0                              ; a0 = shade

				; circle centre address
				move.l  Vid_FastBufferPtr_l,a1
				add.w   d0,a1
				lea     draw_RenderBufferStrideTable_vl,a2 ; stride table from wall plotting code
				move.l  (a2,d1.w*4),d1                     ; y * stride
				add.l   d1,a1                              ; a1 = center address (Xc, Yc)

				; load up the small circle data pointer
				subq.w	#1,d2                              ; radius - 1 = index in table
				lea 	draw_SmallCiclePtrs_vl,a2
				move.l  (a2,d2.w*4),a2                     ; a2 = circle data location

				clr.l   d2
				clr.l   d3
.pairs:
				; Register assignments
				;
				; d0 = offset
				; d1 = -offset
				; d2/d3 = read/remap/write temporaries
				;
				; a0 = shade table slice
				; a1 = circle centre address in framebuffer
				; a2 = offset pointer
				; a3,a4 pixel address caches

				move.w	(a2)+,d0                    ; next offset in list
				beq.s	.done_small                 ; zero terminated

				; d0 and d1 contain the offsets
				move.w	d0,d1
				neg.w   d1
				;st (a1,d0.w)
				;st (a1,d1.w)
				lea     (a1,d0.w),a3
				lea     (a1,d1.w),a4
				move.b  (a3),d2       ; read
				move.b  (a4),d3
				move.b  (a0,d2.w),d2  ; remap
				move.b  (a0,d3.w),d3
				PLOT    d2,(a3)       ; write
				PLOT    d3,(a4)
				bra.s   .pairs

.done_small:
				movem.l  (sp)+,a2-a4
				rts

.ready:
				movem.l d4-d7/a2-a6,-(sp)

				; shade table lookup
				and.l   #$3f,d3
				lsl.l   #8,d3                       ; 256 bytes per slice
				add.l   Draw_PaletteShadeTablePtr_l,d3
				move.l  d3,a0                       ; a0 = shade

				; circle centre address
				move.l  Vid_FastBufferPtr_l,a1
				add.w   d0,a1
				lea     draw_RenderBufferStrideTable_vl,a2 ; stride table from wall plotting code
				move.l  (a2,d1.w*4),d1              ; y * stride
				add.l   d1,a1                       ; a1 = center address (Xc, Yc)

				; row pointers
				move.l  4(a2),d3                    ; d3 = stride
                move.l  (a2,d2.w*4),d0              ; d0 = radius * stride
				move.l  a1,a4
				add.l   d0,a4                       ; a4 = center + (radius * stride)
				move.l  a1,a5
				sub.l   d0,a5                       ; a5 = centre - (radius * stride)
				move.l  a1,a2                       ; a2 = centre row (+y)
				move.l  a1,a3                       ; a3 = centre row (-y)
				move.w  d2,d0                       ; d0.w = x (radius)
				clr.l	d1                          ; d1.w = y (0)
				moveq   #1,d2
				sub.w   d0,d2                       ; err = 1 - radius

				; temporaries for pixel buffering
				clr.l   d4
				clr.l   d5

				; mirror ordinates
				move.w  d0,d6
				neg.w   d6                          ; d6.w = -x
				move.w  d1,d7
				neg.w   d7                          ; d7.w = -y

				; Register assignments:
				;
				; d0 = x
				; d1 = y
				; d2 = err
				; d3 = buffer stride
				; d4,d5 = pixel read/remap temporaries
				; d6 = -x
				; d7 = -y
				;
				; a0 = shade slice
				; a1,a6 = pixel address temporaries (saves calculating indexed modes repeatedly)
				; a2 = row + y
				; a3 = row - y
				; a4 = centre + radius * stride
				; a5 = centre - radius * stride

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				lea     (a2,d0.w),a1                ; Octant A
				lea     (a3,d0.w),a6                ; Octant H
				move.b  (a1),d4                     ; Octant A
				move.b  (a6),d5                     ; Octant H
				move.b  (a0,d4.w),d4
				move.b  (a0,d5.w),d5
				PLOT    d4,(a1)
				PLOT    d5,(a6)
				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				lea     (a2,d6.w),a1                ; Octant D
				lea     (a3,d6.w),a6                ; Octant E
				move.b  (a1),d4                     ; Octant D
				move.b  (a6),d5                     ; Octant E
				move.b  (a0,d4.w),d4
				move.b  (a0,d5.w),d5
				PLOT    d4,(a1)
				PLOT    d5,(a6)
				bra.s   .skip_neg_x

.plot_y0_axis:
				; At y = 0: a2 == a3 => plot (+x, 0) and (-x, 0) just once
				move.b  (a2,d0.w),d4                ; Octant A (+x, 0)
				move.b  (a0,d4.w),d4
				PLOT    d4,(a2,d0.w)
				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				move.b  (a2,d6.w),d4                ; Octant D (-x, 0)
				move.b  (a0,d4.w),d4
				PLOT    d4,(a2,d6.w)

.skip_neg_x:
				; Octants B,C,F,G - skip if x == y to avoid double plot
				cmp.w   d0,d1                       ; x == y
				beq.s   .step                       ; skip transposed octants

				lea     (a4,d1.w),a1                ; Octant B
				lea     (a5,d1.w),a6                ; Octant G
				move.b  (a1),d4
				move.b  (a6),d5
				move.b  (a0,d4.w),d4
				move.b  (a0,d5.w),d5
				PLOT    d4,(a1)
				PLOT    d5,(a6)

				tst.w   d1                          ; skip duplicate y = 0 on horizontal axis
				beq.s   .step

				lea     (a4,d7.w),a1                ; Octant C
				lea     (a5,d7.w),a6                ; Octant F
				move.b  (a1),d4
				move.b  (a6),d5
				move.b  (a0,d4.w),d4
				move.b  (a0,d5.w),d5
				PLOT    d4,(a1)
				PLOT    d5,(a6)

.step:
				tst.w   d2
				ble.s   .step_y

.step_x:
				subq.w  #1,d0                      ; x--
				addq.w  #1,d6                      ; -x++
				sub.l   d3,a4                      ; pointer (yc + x) decrement line
				add.l   d3,a5                      ; pointer (yc - x) increment line
				move.w  d0,d4
				add.w   d4,d4
				addq.w  #1,d4
				sub.w   d4,d2                      ; err -= (2 * x) + 1
				cmp.w   d1,d0                      ; while x >= y
				bge     .loop
				bra.s   .done

.step_y:
				addq.w  #1,d1                      ; y++
				subq.w  #1,d7                      ; -y--
				add.l   d3,a2                      ; pointer (yc + y) increment line
				sub.l   d3,a3                      ; pointer (yc - y) decrement line
				move.w  d1,d4
				add.w   d4,d4
				addq.w  #1,d4
				add.w   d4,d2                      ; err += (2 * y) + 1
				tst.w   d2
				bgt.s   .step_x

				cmp.w   d1,d0                      ; while x >= y
				bge     .loop

.done:
				movem.l (sp)+,d4-d7/a2-a6
				rts

; Called from C init. Sorts out the small circle tables
	DCLC	draw_InitCircleTable
				movem.l d2/a2,-(sp)

				lea     draw_SmallCicleList_vw,a0
				lea     draw_EndSmallCicleList,a1
				lea     draw_RenderBufferStrideTable_vl,a2
				clr.l   d0

				; Convert the -y,x byte pair ordinates in draw_SmallCicleList_vw to signed 16-bit pointer
				; offsets for use in the small circle code path. We use the stride table which is already
				; set up for the width multiplication.
.pair:
				move.b  (a0),d0         ; (positive) y-offset in d0
				move.w  2(a2,d0.w*4),d1 ; fetch the low 16-bits of the 32-bit stride index for the y component.
				move.b  1(a0),d2        ; (signed) x-offset in d2
				ext.w   d2              ; sign extend
				sub.w   d1,d2           ; offset = x - y*stride
				move.w  d2,(a0)+        ; store the (signed) offset
				cmp.l   a0,a1
				bhi.s   .pair

				movem.l (sp)+,d2/a2
				rts
