# Seasonal admin logos

The new admin navigation shows seasonal decorations on the Roští.cz wordmark:

| Occasion | Inclusive dates (Prague time) | Animation |
| --- | --- | --- |
| November 17 | November 17 | Three keys on a ring, shaking briefly every seven seconds |
| August 21 | August 21 | Small static tank at ground level by “tí” |
| Halloween | October 25–November 1 | Bat and pumpkin |
| Christmas | December 20–30 | Santa hat, lights, and snow |
| New Year | December 31–January 1 | Fireworks and confetti |

The original logo appears on all other days. The same artwork is used in the
desktop sidebar and mobile drawer. Open tabs refresh the occasion automatically.
Reduced-motion preferences leave the decorations visible without movement.

Visit `/logos` on the admin domain to review all variants without signing in.
The gallery is public regardless of the admin preference cookie. It shows light and dark
backgrounds and the actual sidebar size, marks the current variant, and includes
a pause/resume button. The gallery contains no account data.

The homepage at `rosti-homepage-astro` uses the same seasonal artwork and date
windows in its navbar, including the Christmas hat centered above the R. All
homepage languages and both responsive layouts share it. Static builds serve the
everyday logo first; the browser selects the current season on hydration and
refreshes it automatically. With JavaScript disabled, the everyday logo remains.
Both projects' `AGENTS.md` files require agents to ask the user whether future
logo changes should also be synced to the other project.

Navbar layout in both projects uses the original wordmark bounds. Decorations
extend around it without shifting its alignment or adding spacing between
navbar items. Enlarged admin gallery previews retain a frame for the decorations.
