#ifndef ZONE_DEBUG_H
#define ZONE_DEBUG_H

/**
 * These functions are to be called from Draw_Zone_Graph when the zone debug flag is set.
 */
extern void ZDbg_Init(void);
extern void ZDbg_First(void);
extern void ZDbg_Enter(void);
extern void ZDbg_Skip(void);
extern void ZDbg_Done(void);

extern void ZDbg_LeftClip(void);
extern void ZDbg_RightClip(void);

#endif // ZONE_DEBUG_H
