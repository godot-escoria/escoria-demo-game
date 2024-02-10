# ASHES Design Principles
## Introduction
This document is meant to reflect the *current* design principles and the rationale behind the decisions made with respect to those principles.

## Principles
### Ease of Use
Escoria is meant to be easy to use, especially for those who don't necessarily come from a strong programming background. ASHES' predecessor, ESCscript, also followed the same design goal, following a similar principle that the original SCUMM sought to embrace.

To that end, ASHES borrows heavily from interpreted languages similar to Python and GDScript. The primary justification for this is to leverage well-established constructs and idioms from languages known for their ability to be learned by inexperienced programmers.

Although this design principle is noble, it is at fundamental odds with other design principles such as the expressiveness and power of a language. To that end, it is possible that the "ease of use" principle may shift in the near future to take into account the increase in uptake of languages such as Python which has undoubtedly reduced the need for Escoria to remain as "basic" as possible.

### Expressiveness/Power
ESCscript was created as a "regular language" (for a discussion on regular languages vs other types, e.g. "context-free", consult your local Google machine). As such, its expressiveness and power were limited. By moving to a context-free language (via a context-free grammar), we do away with the majority of those limitations and fall more in line with more traditional general-purpose languages, albeit with the view of remaining a domain-specific language (or "DSL").

This does not, however, mean that ASHES is as powerful or full-featured as Python or GDScript. In fact, ASHES is meant to act like a DSL (as stated above), meaning that is purpose-built to act on the domain of adventure/point-and-click games. To that end, wherever possible, we use the vernacular and vocabulary of the domain and limit the scope of what the language can do (partly in an attempt from giving game developers too much rope to hang themselves with).

Currently, ASHES is meant to replace ESCscript and maintain certain conventions that are (again, currently) fundamental to Escoria. Such conventions include:

#### Events
Events are explained in-depth in the Escoria documentation (https://docs.escoria-framework.org/en/devel/scripting/z_esc_reference.html#events). They form the backbone of the scripts used by Escoria. While they may just look like a block of ASHES code--much like an ordinary function might--they differ in the following ways:
- Events are typically called from within Escoria itself.
- Events can be called via a specific command in ASHES (`sched_event`), but as can be seen this is done in an indirect manner, different from calling a function by name directly.
- Events don't return values.

#### Commands and Functions
"Commands" are considered to be those that are implemented in GDScript in the "commands" directory (currently `escoria-core/game/core-scripts/esc/commands`), and are called in ASHES by the same convention you would call any function. 

For example, to call the `say` command in ASHES, you can use the line: `say($player, "I am talking.")` and ASHES will bridge the call to the `say` command.

ASHES currently has no facility to accommodate user-defined functions inside of a script itself. In other words, implementing your own function in a script file is not supported. This may be revisited in the future should there be sufficient demand.

You can, however, create your own "command" in the directory mentioned above by extending the base command class and implementing the appropriate methods (see other command scripts in the same directory for examples). While such commands don't currently have access to what is located in the calling ASHES script, it can serve as a one-way bridge to GDScript. Any new commands implemented in this manner can be called directly from ASHES scripts without needing to include them explicitly.

#### Blocking vs Non-blocking Commands
Commands can be either blocking or non-blocking. This isn't an issue unless you are dealing with commands that involve potentially long-running sequences, e.g. an NPC being made to walk a certain route or a camera being slowly panned. In those cases, there exist both blocking and non-blocking versions of the same command. Blocking versions by convention are suffixed with `_block` (e.g .`walk_block`) whereas non-blocking versions have no suffix (e.g. `walk`).

Events are considered to be finished when the last statement has been executed. As such, it is worth being vigilant with the use of blocking and non-blocking commands. For example, if an event consists of a sole `walk` command that has an NPC move through a set of waypoints, the event itself will be considered finished once the `walk` command itself finishes executing. **This does not mean that once the character movement has ceased; rather, when the command that initiates the walk returns.** If you wish for the event to remain active for the duration of the movement, use its blocking equivalent, `walk_block`.

Asynchronous code and state is difficult to manage. As such, we rely on GDScript's underlying facilities to ease that burden, and, as a result, we have chosen to put the responsibility of using blocking and non-blocking commands in the hands of the game developer.


