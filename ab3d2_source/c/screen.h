#ifndef SCREEN_C
#define SCREEN_C

#include <graphics/gfx.h>

#define SCREEN_WIDTH (UWORD)320
#define SCREEN_HEIGHT (UWORD)256
#define SCREEN_DEPTH 8
#define SCREEN_DEPTH_EXP 3

#define HUD_BORDER_WIDTH 16

/**
 * Define GFX_LONG_ALIGNED if you expect to perform 32-bit access vram/chip only
 */
#define GFX_LONG_ALIGNED

#ifndef FS_HEIGHT_HACK
#define FS_HEIGHT (SCREEN_HEIGHT - (UWORD)16)
#define FS_HEIGHT_C2P_DIFF (UWORD)8
#else
#define FS_HEIGHT (SCREEN_HEIGHT - (UWORD)24)
#define FS_HEIGHT_C2P_DIFF (UWORD)0
#endif

#define FS_WIDTH SCREEN_WIDTH
#define SMALL_WIDTH (UWORD)192
#define SMALL_HEIGHT (UWORD)160
#define C2P_FS_HEIGHT (FS_HEIGHT - FS_HEIGHT_C2P_DIFF)

/** 2/3 screensize offsets */
#define SMALL_YPOS 20
#define SMALL_XPOS 64


extern struct MsgPort *Vid_DisplayMsgPort_l;
extern UBYTE Vid_WaitForDisplayMsg_b;
extern struct ScreenBuffer *Vid_ScreenBuffers_vl[2];
extern struct Screen *Vid_MainScreen_l;
extern struct Window *Vid_MainWindow_l;
extern BYTE Vid_DoubleHeight_b;
extern BYTE Vid_DoubleWidth_b;
extern PLANEPTR Vid_Screen1Ptr_l;
extern PLANEPTR Vid_Screen2Ptr_l;
extern ULONG Vid_ScreenMode;
extern BOOL Vid_isRTG;

extern WORD Vid_ScreenHeight;
extern WORD Vid_ScreenWidth;

extern UBYTE Vid_FullScreen_b;

extern void Vid_LoadMainPalette(void);
extern void Vid_OpenMainScreen(void);
extern void vid_SetupDoubleheightCopperlist(void);
extern void Vid_CloseMainScreen(void);
extern void Vid_LoadMainPalette(void);
extern ULONG GetScreenMode();

#endif  // SCREEN_C

