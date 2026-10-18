# Preset Extension (local fork)

Named "agent modes" for Pi: each preset bundles a provider/model, thinking
level, active tool set, and system-prompt instructions, selectable at launch
or mid-session.

Local fork of the shipped
[`examples/extensions/preset.ts`](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/preset.ts)
with three changes:

1. `instructionsFile` may be used instead of `instructions`; the path is
   resolved relative to the agent directory and read when the preset is applied.
2. The `Ctrl+Shift+U` cycle shortcut was removed. Use `/preset`.
3. `session_start` clears the active preset so it does not leak across sessions.

## Usage

- `pi --preset <name>` — start in a preset.
- `/preset` — open the selector.
- `/preset <name>` — activate directly.
- `/preset` → `(none)` — clear and restore the previous state.

Presets are defined in `presets.json`; see that file for the current modes.
