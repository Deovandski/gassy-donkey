// The loading screen's sprite (PixelLoader, #3): shapes on a 32x32 grid (see src/components/reusable/PixelLoader.astro).
// Peeta, copied unchanged from Deovandski/Deovandski (src/lib/pixelPets.ts, the Pets tab's pixel art), the same as
// deovandski.com's loading screen. To use another sprite, add its shapes here (from Deo's art or his say-so) and
// pick it in src/layouts/Base.astro.
type Pt = [number, number];
type Shape =
  | { t: 'ellipse'; cx: number; cy: number; rx: number; ry: number; c: string }
  | { t: 'rect'; x: number; y: number; w: number; h: number; c: string }
  | { t: 'poly'; pts: Pt[]; c: string }
  | { t: 'px'; pts: Pt[]; c: string };

export const PIXEL_PETS: Record<string, { color: string; shapes: Shape[] }> = {
  peeta: {
    color: '#26262b',
    shapes: [
      { t: 'rect', x: 23, y: 16, w: 2, h: 10, c: '#2b2b30' }, // tail
      { t: 'rect', x: 24, y: 14, w: 2, h: 3, c: '#2b2b30' },
      { t: 'ellipse', cx: 16, cy: 23, rx: 7, ry: 6, c: '#2b2b30' }, // body
      { t: 'ellipse', cx: 16, cy: 23, rx: 3, ry: 4, c: '#f4f4f4' }, // white chest
      { t: 'rect', x: 11, y: 28, w: 3, h: 2, c: '#f4f4f4' }, // white paws
      { t: 'rect', x: 18, y: 28, w: 3, h: 2, c: '#f4f4f4' },
      { t: 'poly', pts: [[8, 11], [10, 4], [14, 9]], c: '#2b2b30' }, // ears
      { t: 'poly', pts: [[18, 9], [22, 4], [24, 11]], c: '#2b2b30' },
      { t: 'px', pts: [[10, 7], [10, 8], [22, 7], [22, 8]], c: '#e88aa8' }, // inner ears
      { t: 'ellipse', cx: 16, cy: 14, rx: 7, ry: 6, c: '#2b2b30' }, // head
      { t: 'ellipse', cx: 16, cy: 17, rx: 3, ry: 2, c: '#f4f4f4' }, // white muzzle
      { t: 'px', pts: [[16, 16]], c: '#e88aa8' }, // nose
      { t: 'rect', x: 12, y: 13, w: 2, h: 2, c: '#b6e04a' }, // green eyes
      { t: 'rect', x: 18, y: 13, w: 2, h: 2, c: '#b6e04a' },
      { t: 'px', pts: [[13, 13], [13, 14], [19, 13], [19, 14]], c: '#111111' }, // slit pupils
      { t: 'px', pts: [[7, 17], [8, 17], [9, 17], [23, 17], [24, 17], [25, 17], [8, 19], [24, 19]], c: '#bdbdbd' }, // whiskers
    ],
  },
};
