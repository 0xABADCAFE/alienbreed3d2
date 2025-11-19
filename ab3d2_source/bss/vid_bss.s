			section .bss,bss

			xdef _Vid_ScreenBuffers_vl
			xdef _Vid_Screen1Ptr_l
			xdef _Vid_Screen2Ptr_l
			xdef _Vid_DisplayMsgPort_l
			xdef _Vid_MainScreen_l
			xdef _Vid_MainWindow_l
			xdef _Vid_DoubleHeight_b


; BSS data - to be included in BSS section
			align 4

Vid_C2PSetParamsPtr_l:		ds.l	1	; Points to 1x1 C2P Initialisation for Fullscreen
Vid_C2PConvertPtr_l:		ds.l	1	; Points to 1x1 C2P Conversion for Fullscreen

        ; aligned address
		DCLC Vid_FastBufferPtr_l, ds.l, 1

        ; allocated address
		DCLC Vid_FastBufferAllocPtr_l, ds.l, 1

		DCLC Vid_Screen1Ptr_l, ds.l, 1
		DCLC Vid_Screen2Ptr_l, ds.l, 1
		DCLC Vid_DrawScreenPtr_l, ds.l, 1
		DCLC Vid_DisplayScreenPtr_l, ds.l, 1
		DCLC Vid_ScreenBuffers_vl, ds.l, 2
		DCLC Vid_MainScreen_l, ds.l, 1

Vid_MyRaster0_l:			ds.l	1
Vid_MyRaster1_l:			ds.l	1

		; this message port receives messages when the current screen has been scanned out
		DCLC Vid_DisplayMsgPort_l, ds.l, 1
		DCLC Vid_MainWindow_l, ds.l, 1

;vid_SafeMsgPort_l		ds.l	1			; this message port reveives messages when the old screen bitmap can be safely written to
											; i.e. when the screen flip actually happened

		; Palette data to be submitted to LoadRGB32 calls
		DCLC Vid_LoadRGB32Struct_vl, ds.l, 2

vid_LoadRGB32Data_vl:       ds.l    256*3   ; 32-bit R, B, G
vid_LoadRGB32End_l:         ds.l    1

		; Index (0/1) of current screen buffer displayed.
        ; FIXME: unify the buffer index handling with Vid_DrawScreenPtr_l/Vid_DisplayScreenPtr_l
		DCLC Vid_ScreenBufferIndex_w, ds.w, 1

		; Letter box rendering, height of black border
		DCLC Vid_LetterBoxMarginHeight_w, ds.w, 1

		DCLC Vid_FullScreen_b, ds.b, 1
		DCLC Vid_FullScreenTemp_b, ds.b, 1

		; Double Height Pixels
		DCLC Vid_DoubleHeight_b, ds.b, 1

		; Double Width Pixels
		DCLC Vid_DoubleWidth_b, ds.b, 1

		DCLC Vid_WaitForDisplayMsg_b, ds.b, 1

Vid_ResolutionOption_b:			ds.b	1	; cycles between pixel modes

			align 4

; Menu
		DCLC mnu_palette, ds.l, 256 ; 4byte per pixel, 24bit used
