# Dialog Argument And Translation-Key Plan

## Scope

This plan covers two gaps between the documented ASHES dialog syntax and the
current implementation:

1. Dialog start arguments are parsed but not fully supported end-to-end.
2. Dialog option translation keys are documented but not implemented as a
   first-class language feature.

## Findings

### Dialog start arguments

- The parser currently stores dialog arguments on `ESCGrammarStmts.Dialog`.
- The interpreter does not copy those arguments onto `ESCDialog`, so:
  - `avatar` stays `"-"`
  - `timeout` stays `0`
  - `timeout_option` stays `0`
- The simple dialog chooser already supports these fields once populated.
- There is a syntax mismatch:
  - docs show: `?! "res://avatar" 5 2`
  - parser currently accepts only: `?!(...)`

### Dialog option translation keys

- `say(...)` already supports a dedicated translation key argument.
- Dialog options do not currently have a dedicated translation-key field in the
  AST or runtime types.
- `ESCDialogOption` has a string-prefix fallback (`KEY:text`), but that is not
  equivalent to implementing the documented syntax as a language feature.

## Recommended order

1. Resolve the dialog-start syntax mismatch.
2. Finish interpreter handoff for dialog `avatar`, `timeout`, and
   `timeout_option`.
3. Add first-class dialog option translation-key support.
4. Update or verify docs so they match the implemented syntax exactly.

## Detailed steps

### 1. Resolve dialog-start syntax mismatch

- Add parser regression(s) for the documented dialog-start syntax.
- Decide whether to:
  - support the docs form `?! "res://avatar" 5 2`, or
  - change docs to the implemented `?!(...)` form.
- Preferred direction:
  - support the documented space-separated syntax unless there is a strong
    compatibility reason not to.
- Preserve the existing `?!(...)` form if practical, unless it creates parser
  ambiguity.

### 2. Finish dialog arg handoff

- Add interpreter regression(s) that verify the `ESCDialog` passed to the
  chooser receives:
  - `avatar`
  - `timeout`
  - `timeout_option`
- Implement argument evaluation/mapping in `visit_dialog_stmt()`.
- Reuse `ESCDialog.is_valid()` for runtime validation.

### 3. Implement dialog option translation keys

- Extend `ESCGrammarStmts.DialogOption` with an explicit key field.
- Update parser support for option syntax like:
  - `- UNCLE_SVEN:"Uncle Sven sends regards."`
- Propagate the key through the interpreter into `ESCDialogOption`.
- Update `ESCDialogOption` to prefer the explicit key and keep the current
  `KEY:text` string-prefix behavior as a fallback for compatibility.
- Add parser/interpreter regressions for explicit key handling.

### 4. Final verification

- Run parser and interpreter ASHES suites after each phase.
- Review docs examples against actual parser behavior.
- Remove this temporary plan file once the work is complete.
