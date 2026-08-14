
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
;;
; Uses Jesko Midpoint algorithm to plot 8 octants per loop. Resulds are
; undefied and potentially disasterous if the circle position/size exceed
; the buffer extents.
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
; d3.w shade (-32 - 31) (dark to bright)

_Draw_ShadeCircleUnclipped::
Draw_ShadeCircleUnclipped:
				movem.l d2-d7/a2-a6,-(sp)

				; Shade table slice
				ext.l   d3
				lsl.l   #8,d3                  ; * 256 bytes per slice
				add.l   Draw_TexturePalettePtr_l,d3
				move.l  d3,a0                  ; a0 = slice

				; Centre buffer pointer
				move.l  Vid_FastBufferPtr_l,a1
				ext.l   d0                     ; d0.l = x0
				add.l   d0,a1                  ; a1 = buf = Vid_FastBufferPtr_l + x0

				; Draw buffer
				ext.l   d1                     ; d1.l = y0
				lea     draw_LineOffsetBuffer_vl,a2
				lea     (a2,d1.l*4),a2         ; a2 = &draw_LineOffsetBuffer_vl[y0]

				; X, Y and error
				move.w  d2,d4                  ; d4.w = radius (x)
				ext.l   d4                     ; d4.l = +x
				moveq   #1,d2                  ; d2.w = err
				sub.w   d4,d2                  ; d2.w = err = 1 - radius

				clr.l   d3                     ; d3.l = +y = 0
				suba.l  a4,a4                  ; a4   = -y = 0

				; Zero high-order bytes for byte-lookup registers
				clr.l   d6
				clr.l   d7

				tst.w   d4                     ; Radius < 0 ?
				blt     .done

.loop_start:
				; d4.l = +x, d3.l = +y, a4 = -y
				; Derive -x in d5 far ahead of its use as an AGU index
				move.l  d4,d5
				neg.l   d5                     ; d5.l = -x

				; Load row_y_plus address into a3
				move.l  (a2,d3.l*4),d0
				lea     (a1,d0.l),a3           ; a3 = row_y_plus

				; Octants A & D (Top Half)
				tst.w   d4                     ; x == 0 ?
				beq     .top_single_pixel

.octants_AD:
				; Interleaved pair: row_y_plus[x] & row_y_plus[-x]
				move.b  (a3,d4.l),d6           ; Fetch row_y_plus[+x]
				move.b  (a3,d5.l),d7           ; Fetch row_y_plus[-x]
				move.b  (a0,d6.l),d6           ; Lookup +x
				move.b  (a0,d7.l),d7           ; Lookup -x
				PLOT    d6,(a3,d4.l)           ; Octant A (+x)
				PLOT    d7,(a3,d5.l)           ; Octant D (-x)
				bra     .top_done

.top_single_pixel:
				move.b  (a3,d4.l),d6
				PLOT    (a0,d6.l),(a3,d4.l)

.top_done:
				tst.w   d3                     ; y <= 0 ?
				ble     .check_axis_or_diagonal

				; Load row_y_minus address into a3 (re-using a3 to free registers)
				; Uses a4 (-y) as index
				move.l  (a2,a4.l*4),d0
				lea     (a1,d0.l),a3           ; a3 = row_y_minus

				; Octants E & H (Bottom Half)
				tst.w   d4                     ; x == 0 ?
				beq     .bottom_single_pixel

.octants_EH:
				; Interleaved pair: row_y_minus[x] & row_y_minus[-x]
				move.b  (a3,d4.l),d6           ; Fetch row_y_minus[+x]
				move.b  (a3,d5.l),d7           ; Fetch row_y_minus[-x]
				move.b  (a0,d6.l),d6           ; Lookup +x
				move.b  (a0,d7.l),d7           ; Lookup -x
				PLOT    d6,(a3,d4.l)           ; Octant H (+x)
				PLOT    d7,(a3,d5.l)           ; Octant E (-x)
				bra     .bottom_done

.bottom_single_pixel:
				move.b  (a3,d4.l),d6
				PLOT    (a0,d6.l),(a3,d4.l)

.bottom_done:
				cmp.w   d4,d3                  ; x == y ?
				beq     .step

.octants_BCFG:
				; Load row_x_plus (a5) and row_x_minus (a6)
				; d4 = +x, d5 = -x
				move.l  (a2,d4.l*4),d0
				lea     (a1,d0.l),a5           ; a5 = row_x_plus

				move.l  (a2,d5.l*4),d0
				lea     (a1,d0.l),a6           ; a6 = row_x_minus

				; Octants B & C Pair: row_x_plus[y] & row_x_plus[-y]
				; Uses d3 (+y) and a4 (-y) directly—no mid-block negations!
				move.b  (a5,d3.l),d6           ; Load row_x_plus[+y]
				move.b  (a5,a4.l),d7           ; Load row_x_plus[-y]
				move.b  (a0,d6.l),d6
				move.b  (a0,d7.l),d7
				PLOT    d6,(a5,d3.l)           ; Octant B (+y)
				PLOT    d7,(a5,a4.l)           ; Octant C (-y)

				; Octants F & G Pair: row_x_minus[-y] & row_x_minus[y]
				move.b  (a6,d3.l),d6           ; Load row_x_minus[+y]
				move.b  (a6,a4.l),d7           ; Load row_x_minus[-y]
				move.b  (a0,d6.l),d6
				move.b  (a0,d7.l),d7
				PLOT    d6,(a6,d3.l)           ; Octant G (+y)
				PLOT    d7,(a6,a4.l)           ; Octant F (-y)

.step:
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
				move.l  (a2,d4.l*4),d0
				lea     (a1,d0.l),a5           ; row_x_plus (+x)

				move.l  (a2,d5.l*4),d0
				lea     (a1,d0.l),a6           ; row_x_minus (-x)

				; Pair *row_x_plus & *row_x_minus
				move.b  (a5),d6
				move.b  (a6),d7
				move.b  (a0,d6.l),d6
				move.b  (a0,d7.l),d7
				PLOT    d6,(a5)                ; Bottom axis
				PLOT    d7,(a6)                ; Top axis

				tst.w   d2
				bgt     .step_x
				bra     .step_y
