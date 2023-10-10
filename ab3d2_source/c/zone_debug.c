#include "system.h"
#include "zone_debug.h"
#include <stdio.h>

extern WORD Draw_CurrentZone_w;

extern void ZDbg_Init(void)
{

}

extern void ZDbg_Dump(void)
{
	printf("Zone %d\n", (int)Draw_CurrentZone_w);
}

extern void ZDbg_Done(void)
{

}
