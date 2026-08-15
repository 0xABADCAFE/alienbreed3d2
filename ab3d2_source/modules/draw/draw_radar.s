
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


; Unclipped Circle Routine : Hand tuned from compiler output
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

Draw_ShadeCircleUnclipped:
				tst.w   d2
				bgt.s   .ready

; TODO
; For small radii, e.g. < 16 pixels we can just have a precalculated list of
; x,y word coordinates. We can convert those into buffer position offsets during
; initialisation, once we know what the span width is (for future upgrades to
; resolution). Since these values are points on the circumference, we can simply
; zero terminate the list.
;
; Note, we'd only need to store the offsets for a half-circle and apply them as
; addition and subtraction offsets from the centre address.

				rts

.ready:
				movem.l d2-d7/a2-a5,-(sp)

				; shade table lookup
				and.l   #$3f,d3
				lsl.l   #8,d3                       ; 256 bytes per slice
				add.l   Draw_TexturePalettePtr_l,d3
				move.l  d3,a0                       ; a0 = shade

				; circle centre address
				move.l  Vid_FastBufferPtr_l,a1
				add.w   d0,a1
				lea     draw_LineOffsetBuffer_vl,a2 ; stride table from wall code
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

.loop:
				; Octants A,D,E,H
				tst.w   d1                          ; y == 0?
				beq.s   .plot_y0_axis               ; at y = 0, a2 == a3, avoid double plot

				move.b  (a2,d0.w),d4                ; Octant A
				move.b  (a3,d0.w),d5                ; Octant H
				move.b  (a0,d4.w),d4
				move.b  (a0,d5.w),d5
				PLOT    d4,(a2,d0.w)
				PLOT    d5,(a3,d0.w)
				tst.w   d0                          ; skip duplicate x = 0 on vertical axis
				beq.s   .skip_neg_x

				move.b  (a2,d6.w),d4                ; Octant D
				move.b  (a3,d6.w),d5                ; Octant E
				move.b  (a0,d4.w),d4
				move.b  (a0,d5.w),d5
				PLOT    d4,(a2,d6.w)
				PLOT    d5,(a3,d6.w)
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

				move.b  (a4,d1.w),d4                ; Octant B
				move.b  (a5,d1.w),d5                ; Octant G
				move.b  (a0,d4.w),d4
				move.b  (a0,d5.w),d5
				PLOT    d4,(a4,d1.w)
				PLOT    d5,(a5,d1.w)

				tst.w   d1                          ; skip duplicate y = 0 on horizontal axis
				beq.s   .step

				move.b  (a4,d7.w),d4                ; Octant C
				move.b  (a5,d7.w),d5                ; Octant F
				move.b  (a0,d4.w),d4
				move.b  (a0,d5.w),d5
				PLOT    d4,(a4,d7.w)
				PLOT    d5,(a5,d7.w)

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
				movem.l (sp)+,d2-d7/a2-a5
				rts
