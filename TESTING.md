# Testing

## Scope
This project uses `gdUnit4` as the active automated test framework for Godot 4.x. The priority is a regression suite for the ASHES language pipeline in `addons/escoria-core/game/core-scripts/esc/compiler/`.

The old `addons/escoria-core/_test/` directory is deprecated and should not be used for new work.

## Test Layout
- `addons/escoria-core/testing/ashes/scanner/`: tokenization and indentation tests
- `addons/escoria-core/testing/ashes/parser/`: parser shape, parse-error, and recovery tests
- `addons/escoria-core/testing/ashes/resolver/`: scope and name-resolution tests
- `addons/escoria-core/testing/ashes/interpreter/`: execution semantics and command dispatch tests
- `addons/escoria-core/testing/ashes/integration/`: small end-to-end language/runtime tests only where direct object tests are insufficient

Keep tests narrow and deterministic. Prefer direct `ESCScanner`, `ESCParser`, `ESCResolver`, and `ESCInterpreter` tests over scene-driven tests.

## Current Goals
The first goal is to build a regression suite around the ASHES compiler/runtime so refactors do not silently change behavior.

Priority coverage:
- scanner token boundaries, comments, strings, globals, and indentation/dedentation
- parser synchronization after malformed input
- parser handling for `if`, `while`, dialogs, `break`, and `done`
- resolver scope depth, shadowing, and initializer errors
- interpreter block scope restoration, control flow propagation, and builtin behavior

Add a focused regression test whenever fixing a compiler, parser, resolver, or interpreter bug.

## IDE Workflow
To verify that the project and `gdUnit4` load correctly in the Godot IDE:

```sh
"<godot_binary>" --editor --quit-after 2 --path .
```

You can also use the `gdUnit4` UI inside the editor to run individual suites during local debugging.

## CLI Workflow
Run a single suite through the shipped `gdUnit4` wrapper:

```sh
./addons/gdUnit4/runtest.sh --godot_binary "<godot_binary>" -a res://addons/escoria-core/testing/ashes/parser/esc_parser_test.gd
```

Replace `<godot_binary>` with the Godot 4.5+ executable for the current operating system. That can be a binary on `PATH` or an absolute path.

The wrapper returns `gdUnit4`'s exit code:
- `0` for success
- non-zero for failures or runner problems

## Headless Workflow
`gdUnit4` does not allow headless execution by default. A plain `--headless` run exits with code `103`.

For non-UI suites only, use:

```sh
"<godot_binary>" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://addons/escoria-core/testing/ashes/parser/esc_parser_test.gd
```

Do not use `--ignoreHeadlessMode` for tests that rely on UI interaction, scene input, or `InputEvent` propagation.

## Notes
- `gdUnit4` writes reports under `reports/`.
- Existing asset UID warnings in this project are unrelated to ASHES tests, but they still appear in CLI output.
- For compiler pipeline work, prefer asserting behavior directly rather than asserting on logs.

## New-game room lifecycle

Run the focused core lifecycle regression suite with:

```sh
"<godot_binary>" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://addons/escoria-core/testing/new_game_room_lifecycle_test.gd
```

`-c` runs all cases after a failure. The suite uses minimal scenes under
`addons/escoria-core/testing/new_game/` with the real room manager, object
manager, ASHES runtime, and scene tree. It checks starting-room restart, restart
from another room, repeated restart, object registration before `:setup` and
after old-room deletion, ordinary same-room transitions, and same-room loading.
The loading case exercises the manager branch with `is_loading_game`; it does
not read a saved file.

The paused-menu case calls the actual game pause methods while an ASHES wait
event is active. It does not synthesize input or verify menu rendering, so
headless execution is appropriate. Dialogue interaction and a manual gameplay
walkthrough remain separate checks.

Also run `esc_object_manager_test.gd` and `issue_946_room_transition_test.gd` in
the same testing directory for adjacent registration and room-transition
coverage. Treat compiler/import failures as validation blockers, distinct from
lifecycle assertion failures; do not infer successful runtime validation from
a test runner that could not load its dependencies.
