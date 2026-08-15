
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
; This is a modification of the compiler generated baseline that aims to
; pair octant read/remap/write cycles to avoid AGU stalls.
;
; Params
; d0.w centreX
; d1.w centreY
; d2.w radius
; d3.w shade (0 - 31 white to normal, 32-63 normal to black)

Draw_ShadeCircleUnclipped:
				tst.w	d2
				bgt.s	.ready ; radius > 0

				; TODO
				; For small radii, e.g. < 16 pixels we can just have a precalculated list of
				; x,y word coordinates. We can convert those into buffer position offsets during
				; initialisation, once we know what the span width is (for future upgrades to resolution).
				; Since these values are points on the circumference, we can simply zero terminate the list.

				rts

.ready:
				movem.l d2-d7/a2-a6,-(sp)

				; Shade table slice
				and.l   #$3f,d3
				lsl.l   #8,d3                        ; 256 bytes per slice
				add.l   Draw_TexturePalettePtr_l,d3  ;
				move.l  d3,a0                        ; a0 = slice

				; Centre buffer pointer. Calculate the position in the render buffer that corresponds to
				; the circle centre.
				move.l  Vid_FastBufferPtr_l,a1
				add.w   d0,a1                        ; a1 = buf = Vid_FastBufferPtr_l + x0

				; Span buffer (borrowed from the wall renderer)
				; TODO - We should be able to move away from using this and update the pointers when the
				;        y step changes. Failing that, for 68060 we can use multiplication to get to the
				;        required y offset.
				;
				lea     draw_LineOffsetBuffer_vl,a2
				lea     (a2,d1.w*4),a2               ; a2 = &draw_LineOffsetBuffer_vl[y0]

				; X, Y and error
				move.w  d2,d4                        ; d4.w = radius (x)
				moveq   #1,d2                        ; d2.w = err
				sub.w   d4,d2                        ; d2.w = err = 1 - radius
				clr.l   d3                           ; d3.w = +y = 0
				move.l  d3,a4                        ; a4.w = -y = 0

				; Using d6/d7 to hold the input pixels for the shade table lookup.
				clr.l   d6
				clr.l   d7

.loop_start:
				move.w  d4,d5                        ; d4.w = +x
				neg.w   d5                           ; d5.w = -x

				; Load row_y_plus address into a3
				move.l  (a2,d3.w*4),d0
				lea     (a1,d0.l),a3                 ; a3 = row_y_plus

				; Octants A & D (Top Half)
				tst.w   d4                           ; x == 0 ?
				beq     .top_single_pixel

.octants_AD:
				; Interleaved pair: row_y_plus[x] & row_y_plus[-x]
				move.b  (a3,d4.w),d6           ; Read A
				move.b  (a3,d5.w),d7           ; Read D
				move.b  (a0,d6.w),d6           ; Remap A
				move.b  (a0,d7.w),d7           ; Remap D
				PLOT    d6,(a3,d4.w)           ; Write A
				PLOT    d7,(a3,d5.w)           ; Write D
				bra     .top_done

.top_single_pixel:
				move.b  (a3,d4.w),d6
				PLOT    (a0,d6.w),(a3,d4.w)

.top_done:
				tst.w   d3                     ; y <= 0 ?
				ble     .check_axis_or_diagonal

				; Load row_y_minus address into a3 (re-using a3 to free registers)
				; Uses a4 (-y) as index
				move.l  (a2,a4.w*4),d0
				lea     (a1,d0.l),a3           ; a3 = row_y_minus

				; Octants E & H (Bottom Half)
				tst.w   d4                     ; x == 0 ?
				beq     .bottom_single_pixel

.octants_EH:
				; Interleaved pair: row_y_minus[x] & row_y_minus[-x]
				move.b  (a3,d4.w),d6           ; Read H
				move.b  (a3,d5.w),d7           ; Read E
				move.b  (a0,d6.w),d6           ; Remap H
				move.b  (a0,d7.w),d7           ; Remap E
				PLOT    d6,(a3,d4.w)           ; Write H
				PLOT    d7,(a3,d5.w)           ; Write E
				bra     .bottom_done

.bottom_single_pixel:
				move.b  (a3,d4.w),d6
				PLOT    (a0,d6.w),(a3,d4.w)

.bottom_done:
				cmp.w   d4,d3                  ; x == y ?
				beq     .step

.octants_BCFG:
				; Load row_x_plus (a5) and row_x_minus (a6)
				; d4 = +x, d5 = -x
				move.l  (a2,d4.w*4),d0
				lea     (a1,d0.l),a5           ; a5 = row_x_plus

				move.l  (a2,d5.w*4),d0
				lea     (a1,d0.l),a6           ; a6 = row_x_minus

				; Octants B & C Pair: row_x_plus[y] & row_x_plus[-y]
				; Uses d3 (+y) and a4 (-y) directly—no mid-block negations!
				move.b  (a5,d3.w),d6           ; Read B
				move.b  (a5,a4.w),d7           ; Read C
				move.b  (a0,d6.w),d6           ; Remap B
				move.b  (a0,d7.w),d7           ; Remap C
				PLOT    d6,(a5,d3.w)           ; Write B
				PLOT    d7,(a5,a4.w)           ; Write C

				; Octants F & G Pair: row_x_minus[-y] & row_x_minus[y]
				move.b  (a6,d3.w),d6           ; Read G
				move.b  (a6,a4.w),d7           ; Read F
				move.b  (a0,d6.w),d6           ; Remap G
				move.b  (a0,d7.w),d7           ; Remap F
				PLOT    d6,(a6,d3.w)           ; Write G
				PLOT    d7,(a6,a4.w)           ; Write F

.step:
				; This is the Jesko iteration
				tst.w   d2                     ; err <= 0 ?
				ble     .step_y

.step_x:
				subq.w  #1,d4                  ; x--
				move.w  d4,d0
				lsl.w   #1,d0                  ; x * 2
				not.w   d0                     ; ~(x * 2) = -2x - 1
				add.w   d0,d2                  ; err -= (x * 2) + 1
				cmp.w   d3,d4                  ; x >= y ?
				bge     .loop_start

.done:
				movem.l (sp)+,d2-d7/a2-a6
				rts

.step_y:
				addq.w  #1,d3                  ; y++
				suba.l  a4,a4
				suba.l	d3,a4                  ; a4  = -y
				addq.w  #1,d2                  ; err++
				move.w  d3,d0
				lsl.w   #1,d0                  ; y * 2
				add.w   d0,d2                  ; err += (y * 2)
				tst.w   d2                     ; err > 0 ?
				bgt     .step_x

				cmp.w   d3,d4                  ; x >= y ?
				bge     .loop_start
				bra     .done

.check_axis_or_diagonal:
				cmp.w   d4,d3
				beq     .step

				tst.w   d3
				bne     .octants_BCFG

				tst.w   d4
				beq     .step

.vertical_axis:
				move.l  (a2,d4.w*4),d0
				lea     (a1,d0.l),a5           ; row_x_plus (+x)

				move.l  (a2,d5.w*4),d0
				lea     (a1,d0.l),a6           ; row_x_minus (-x)

				; Pair *row_x_plus & *row_x_minus
				move.b  (a5),d6                ; Read Bottom
				move.b  (a6),d7                ; Read Top
				move.b  (a0,d6.w),d6           ; Remap Bottom
				move.b  (a0,d7.w),d7           ; Remap Top
				PLOT    d6,(a5)                ; Write Bottom
				PLOT    d7,(a6)                ; Write Top
				tst.w   d2
				bgt     .step_x
				bra     .step_y
