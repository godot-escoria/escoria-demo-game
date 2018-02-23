# Using git submodules to develop a game

Caveat: This is not necessarily the one true way. The framework and its practices
are constantly being developed, but this document contains some pointers.

Submodules are a bit advanced and specific to your project, and therefore the commands
you may use are as well. You can get into Git [here](https://git-scm.com/book/en/v1/Getting-Started).

This is the [chapter on submodules](https://git-scm.com/book/en/v1/Git-Tools-Submodules).

## Why?

Git's strength is in how well it handles remotes and branches. This may go beyond
Git 101, but it's a very efficient way to work once you get into it.

Having the framework separate from your game also helps to identify changes to the
code you may have to make. The goal of a framework is to be completely separate from
whatever it's used for, so please open issues on GitHub if you find yourself making
changes to the framework that aren't bugfixes or new features.

If possible, please make a PR that alters Escoria's behavior, eg. through `ProjectSettings`,
so that the change doesn't happen in Escoria's upstream code.

You may read more about this in the ../CONTRIBUTING.md document.

## How?

Create a git repository and add the Escoria GitHub URL as a remote, eg. `gh-escoria`.
This document will refer to your repository as `origin`.

Reset your `master` to match whatever `gh-escoria/master` is at the time.

Escoria is not (at the time of writing this) at the stage where you never have to touch
the framework code. Whether you contribute or not, or whatever workflow you want to use,
this document will refer to your work branch as `devel`. This is checked off of `master`.

The project root is `device/`. It contains your project settings. When submitting branches
for merging, please do not include your game's settings. Any new features should be disabled
by default, to not mess with the tutorial [*Creating Point and Click Games with Escoria*](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/).

## Actual work

Create a new repository for the submodule.

Add it as `device/game/`.

You can also create subdirectories like `rooms`, `actors` and `items`. The best practices are
not clearly defined yet, but such a naming scheme correlates with tradition. As your game comes
along, you will logically create a subdirectory for every item or actor and so on.

Now you're ready to launch Godot!

## Misc notes

Whatever is parallel to `game/` can be copied under `game/` and the project structure changed
accordingly. This is your last resort if you can't expose a setting.

As another use case, if you want to use the `demo/ui/action_menu.tscn` for a template, you could
copy it under `game/ui/` - your submodule - and maintain it there.

In case you want to edit the "heads-up display", `ui/hud.tscn`, you will have to do it in-tree
at least for the time being. Take care not to include it in any PRs upstream.

If you want to contribute to Escoria upstream, please do not submit a branch that is based on
`devel`. It may feel like branch acrobatics to have one taken off `master` and rebased onto
`devel` for live work, maybe even cherry-pick-squashing changes from the `devel` version onto
the `master` version, but it is necessary to keep the Escoria code base as clean as possible.

