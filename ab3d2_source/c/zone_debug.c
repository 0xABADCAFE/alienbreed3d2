#include "system.h"
#include "zone_debug.h"
#include <stdio.h>

extern WORD Draw_CurrentZone_w;
extern LONG Sys_FrameNumber_l;
extern LONG Draw_LeftClip_l;
extern LONG Draw_RightClip_l;

extern WORD Draw_LeftClip_w;
extern WORD Draw_RightClip_w;

extern void ZDbg_Init(void)
{
	printf("Zone Trace [Frame: %d]\n", Sys_FrameNumber_l);
}

extern void ZDbg_Enter(void)
{
    printf(
        "\tEntering Zone %3d: Left: %d, Right %d\n",
        (int)Draw_CurrentZone_w,
        Draw_LeftClip_l,
        Draw_RightClip_l
    );
}

extern void ZDbg_Skip(void)
{
    printf(
        "\tSkipping Zone %3d: Left: %d, Right %d\n",
        (int)Draw_CurrentZone_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
}


extern void ZDbg_Done(void)
{
	printf("\tEnd trace\n");
}
