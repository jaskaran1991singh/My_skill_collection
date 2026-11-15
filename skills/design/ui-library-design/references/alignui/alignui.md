# AlignUI

> **Authored guide, no upstream skill.** AlignUI publishes no official agent skill or `llms.txt` (checked Nov 2026: the `alignui` GitHub org has only a `cli` repo for Tailwind token setup). This page is written from the public docs at `alignui.com/docs`. Treat specifics as **verify-before-use**: open the matching docs page before you write production code.

## What it is
- A Figma design system with a matching **copy-paste React code library**: you own the files. There is no single runtime npm package of components.
- Stack: **React + Tailwind CSS + Radix UI primitives**, `tailwind-variants` (`tv`) for variants, and `tailwind-merge`. Icons come from **Remix Icon** (`@remixicon/react`).
- Free tier: the base components. **AlignUI Pro** adds templates, blocks and more components (licensed). Don't paste Pro code into a project unless the user has a license.

## Setup (verify against current docs)
1. Start with a Next.js or Vite React app on Tailwind.
2. Use the CLI to generate tokens and Tailwind config: `npx @alignui/cli@<version> tailwind`. It writes the AlignUI color, typography and shadow tokens into the Tailwind setup.
3. Copy the needed component files (for example `components/ui/button.tsx`) and the shared `utils/` helpers (`cn`/`tv`, polymorphic helpers) from the docs into the project.
4. Install the peer dependencies each component lists: `@radix-ui/react-*`, `tailwind-variants`, `tailwind-merge`, `@remixicon/react`.

## Design language
- **Neutral-first, crisp SaaS look**: white or bg-weak surfaces, 1px stroke borders, small radii (8–12px on cards, 10px on controls), and subtle "regular" shadows.
- **Semantic tokens** (the names roughly mirror the docs, so confirm them in the generated config):
  - backgrounds `bg-white-0`, `bg-weak-50`, `bg-soft-200`, `bg-sub-300`, `bg-surface-800`, `bg-strong-950`
  - text `text-strong-950`, `text-sub-600`, `text-soft-400`, `text-disabled-300`, `text-white-0`
  - strokes `stroke-soft-200`, `stroke-sub-300`, `stroke-strong-950`
  - state families: `primary`, `information`, `success`, `warning`, `error`, `feature`, `highlighted`, `stable`, `faded`, `away`, `verified`, each with `-dark`/`-base`/`-light`/`-lighter`
- **Typography scale** as utilities: `text-title-h1…h6`, `text-label-xl…xs`, `text-paragraph-xl…xs`, `text-subheading-md…2xs`. Use these instead of raw `text-sm font-medium`.
- **Component API pattern**: compound, Radix-style parts with variant props through `tv`:
```tsx
import * as Button from '@/components/ui/button';
import { RiAddLine } from '@remixicon/react';

<Button.Root variant="primary" mode="filled" size="medium">
  <Button.Icon as={RiAddLine} />
  New project
</Button.Root>
```
  Common props are `variant` (`primary | neutral | error`), `mode` (`filled | stroke | lighter | ghost`) and `size` (`medium | small | xsmall | xxsmall`). Check each component's docs, because names differ per component.
- Core building blocks: Button, FancyButton, CompactButton, LinkButton, Input (`Input.Root/Wrapper/Input/Icon/Affix`), Label, Hint, Select, Checkbox, Radio, Switch, Badge, StatusBadge, Tag, Avatar/AvatarGroup, Tooltip, Modal, Drawer, Dropdown, Popover, Tabs (`TabMenuHorizontal`/`Vertical`), SegmentedControl, Table, Pagination, Notification/Toast, Alert, ProgressBar/Circle, Divider, Kbd, DatePicker, FileUpload, Accordion, Breadcrumb, CommandMenu.

## Rules
- Match spacing to the 4px grid and use AlignUI tokens. Never hard-code hex values when a token exists.
- Pair every input with `Label` + `Hint` (error state through `hasError`).
- Keep one primary `filled` action per view. Use `stroke`/`ghost` for secondary actions.
- Dark mode comes from the token layer (the `.dark` class), not per-component overrides.
