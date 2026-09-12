#include "defs.h"
#include "draw.h"
#include "system.h"

// TODO this code is awful

extern LONG draw_RenderBufferStrideTable_vl[];
extern WORD Vid_RightX_w;
extern WORD Vid_BottomY_w;

#define QUADRANT_BIT_BR 1
#define QUADRANT_BIT_BL 2
#define QUADRANT_BIT_TL 4
#define QUADRANT_BIT_TR 8

static inline void putPixel(WORD x, WORD y, const uint8_t* restrict pShade, uint8_t* restrict pDraw)
{
    if (x >= 0 && x < Vid_RightX_w && y >= 0 && y < Vid_BottomY_w) {
        UBYTE* pDest = pDraw + draw_RenderBufferStrideTable_vl[y] + x;
        *pDest = pShade[*pDest];
    }
}

/**
 * This is our ugly unoptimised version. Since we're dealing with edge cases (no pun intended) I don't
 * plan to worry about this too much.
 */
void draw_SCUPartialClipped(
    REG(d0, WORD x0),
    REG(d1, WORD y0),
    REG(d2, WORD radius),
    REG(d3, UWORD quadrants),
    REG(a0, UBYTE const* restrict pShade)
)
{
    UBYTE * restrict pDraw = Vid_FastBufferPtr_l;
    WORD x = radius, y = 0, err = 1 - radius;
    while (x >= y) {
        WORD px_p = x0 + x, px_m = x0 - x, py_p = y0 + y, py_m = y0 - y;

        if (quadrants & QUADRANT_BIT_BR) putPixel(px_p, py_p, pShade, pDraw);
        if (quadrants & QUADRANT_BIT_BL) putPixel(px_m, py_p, pShade, pDraw);
        if (quadrants & QUADRANT_BIT_TL) putPixel(px_m, py_m, pShade, pDraw);
        if (quadrants & QUADRANT_BIT_TR) putPixel(px_p, py_m, pShade, pDraw);

        if (x != y && y != 0) {
            WORD qx_p = x0 + y, qx_m = x0 - y, qy_p = y0 + x, qy_m = y0 - x;
            if (quadrants & QUADRANT_BIT_BR) putPixel(qx_p, qy_p, pShade, pDraw);
            if (quadrants & QUADRANT_BIT_BL) putPixel(qx_m, qy_p, pShade, pDraw);
            if (quadrants & QUADRANT_BIT_TL) putPixel(qx_m, qy_m, pShade, pDraw);
            if (quadrants & QUADRANT_BIT_TR) putPixel(qx_p, qy_m, pShade, pDraw);
        } else if (y == 0 && x != 0) {
            putPixel(x0, y0 + x, pShade, pDraw);
            putPixel(x0, y0 - x, pShade, pDraw);
        }
        if (err <= 0) {
            y++;
            err += (y << 1) + 1;
        }
        if (err > 0) {
            x--;
            err -= (x << 1) + 1;
        }
    }
}
