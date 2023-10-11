#include "system.h"
#include "zone_debug.h"
#include "message.h"
#include <stdio.h>

extern WORD Draw_CurrentZone_w;
extern LONG Sys_FrameNumber_l;
extern LONG Draw_LeftClip_l;
extern LONG Draw_RightClip_l;

extern WORD Draw_LeftClip_w;
extern WORD Draw_RightClip_w;

extern LONG Plr1_Position_vl[3];
extern WORD Plr1_Direction_vw[4];

extern WORD SetClipStage_w;

extern void* Dev_RegStatePtr;

extern ULONG Dev_DebugFlags;

#define DEV_ZONE_TRACE_VERBOSE_AF (1<<14)

static void ZDbg_ShowRegs(void)
{
    if (Dev_RegStatePtr) {
        ULONG *reg = (ULONG*)Dev_RegStatePtr;
        puts("\tRegister Dump");
        for (int i=0; i<8; ++i) {
            UWORD *regw = ((UWORD*)&reg[i])+1;
            UBYTE *regb = ((UBYTE*)&reg[i])+3;
            printf(
                "\t\td%d: 0x%08X | %10u .l | %+11d .l | %5u .w | %+6d .w | %3u .b | %+4d .b |\n",
                i, (unsigned)reg[i], (unsigned)reg[i], (int)reg[i],
                (unsigned)*regw,
                (int)*((WORD*)regw),
                (unsigned)*regb,
                (int)*((BYTE*)regb)
            );
        }
        reg = ((ULONG*)(Dev_RegStatePtr))+8;
        for (int i=0; i<7; ++i) {
            printf(
                "\t\ta%d: 0x%08X\n",
                i, (unsigned)reg[i]
            );
        }
        printf(
            "\t\ta7: 0x%08X\n\n",
            (unsigned)Dev_RegStatePtr
        );
    }
}

void ZDbg_Init(void)
{
    Msg_PushLine("Dumping PVS trace...", MSG_TAG_OTHER|20);
    printf(
        "Draw_Zone_Graph()\n"
        "\tFrame: %d\n"
		"\tDebug: 0x%08X\n"
        "\tPlayer {X:%d, Y:%d, Z:%d}, {cos:%d, sin:%d, ang:%d}\n",
        Sys_FrameNumber_l,
		Dev_DebugFlags,
        Plr1_Position_vl[0]>>16,
        Plr1_Position_vl[1]>>16,
        Plr1_Position_vl[2]>>16,
        (int)Plr1_Direction_vw[0],
        (int)Plr1_Direction_vw[1],
        (int)Plr1_Direction_vw[2],
        (int)Plr1_Direction_vw[3]
    );
}

void ZDbg_First(void)
{
    printf(
        "Beginning PVS at Zone %d\n",
        (int)Draw_CurrentZone_w
    );
    if (Dev_DebugFlags & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}


void ZDbg_Enter(void)
{
    printf(
        "\nDECISION: RENDER ZONE %3d [L:%d R:%d]\n",
        (int)Draw_CurrentZone_w,
        Draw_LeftClip_l,
        Draw_RightClip_l
    );
    if (Dev_DebugFlags & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}

void ZDbg_Skip(void)
{
    printf(
        "\nDECISION: SKIP ZONE %3d [L:%d R:%d]\n",
        (int)Draw_CurrentZone_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
    if (Dev_DebugFlags & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}


void ZDbg_Done(void)
{
    puts("\tEnd trace");
}

void ZDbg_LeftClip(void)
{
    printf(
        "\tLeft Clip: %d [L:%d R:%d]\n",
        (int)SetClipStage_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
    if (Dev_DebugFlags & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}

void ZDbg_RightClip(void)
{
    printf(
        "\tRight Clip: %d [L:%d R:%d]\n",
        (int)SetClipStage_w,
        (int)Draw_LeftClip_w,
        (int)Draw_RightClip_w
    );
    if (Dev_DebugFlags & DEV_ZONE_TRACE_VERBOSE_AF) {
        ZDbg_ShowRegs();
    }
}
