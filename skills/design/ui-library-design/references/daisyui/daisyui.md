# daisyUI 5

> Upstream: `saadeghi/daisyui` › `skills/daisyui` (MIT). **Cleaned:** the upstream description told the agent to use daisyUI for *all* HTML/JSX "even if the user does not request it". That instruction has been removed: it hijacks unrelated tasks and overrides the project's chosen stack. Use daisyUI only when the project already uses it or the user picks it. The sub-guides and component files passed the audit unchanged.

daisyUI 5 is a CSS plugin for **Tailwind CSS 4**. It provides semantic component class names (`btn`, `card`, `modal`…), semantic colors (`primary`, `base-100`…) and 35+ themes. It ships no JavaScript, so it works with any framework or plain HTML.

## Read before writing code
| Task | File |
|---|---|
| Install / project has no daisyUI | `./install.md` |
| Before using any class names | `./usage.md` |
| Before using colors and themes | `./colors.md` |
| Themes, prefix, include/exclude | `./config.md` |
| Specific components | `./components/<name>.md` |

## Component discovery
1. Work out the intended *function* and layout, not just the words in the request.
2. Pick candidates from `./components/` (accordion, alert, avatar, badge, breadcrumbs, button, calendar, card, carousel, chat, checkbox, collapse, countdown, diff, divider, dock, drawer, dropdown, fab, fieldset, file-input, filter, footer, hero, hover-3d, hover-gallery, indicator, input, join, kbd, label, link, list, loading, mask, megamenu, menu, mockup-*, modal, navbar, otp, pagination, progress, radial-progress, radio, range, rating, select, skeleton, stack, stat, status, steps, swap, tab, table, text-rotate, textarea, theme-controller, timeline, toast, toggle, tooltip, validator).
3. When the choice is unclear, read more than one candidate guide. Then follow the selected component's exact structure and constraints.

## Key rules (summary of usage.md)
- Use component, part and modifier classes, and use Tailwind utilities for anything daisyUI doesn't cover.
- Use the default variant unless the user asked for one (`btn`, not `btn btn-primary`).
- Use semantic colors (`bg-base-200`, `text-base-content/60`) so themes and dark mode work.
- Add responsive prefixes on flex/grid layouts. Avoid custom CSS and custom fonts unless they're needed.
