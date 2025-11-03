#!/usr/bin/env python3
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple


ROOT = Path("addons/escoria-core")

DEFAULT_PARAM_DESC = "No description provided."

PARAM_OVERRIDES_BY_SIGNATURE = {
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_grammar_stmts.gd",
        "func init(name: ESCToken, initializer: ESCGrammarExpr):",
        "name",
    ): "Token representing the variable's name.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_grammar_stmts.gd",
        "func init(name: ESCToken, target: ESCGrammarExprs.Literal, flags: Dictionary, body: ESCGrammarStmts.Block, object_global_id: String):",
        "name",
    ): "Token representing the event name.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_grammar_exprs.gd",
        "func init(name: ESCToken):",
        "name",
    ): "Token representing the variable's name.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_grammar_exprs.gd",
        "func init(name: ESCToken, value: ESCGrammarExpr):",
        "name",
    ): "Token representing the variable's name to assign.",
}

PARAM_OVERRIDES_BY_FUNCTION = {
    (
        "addons/escoria-core/game/esc_project_settings_manager.gd",
        "register_setting",
        "name",
    ): "Fully qualified Project Settings key to register.",
    (
        "addons/escoria-core/game/esc_project_settings_manager.gd",
        "remove_setting",
        "name",
    ): "Fully qualified Project Settings key to remove.",
    (
        "addons/escoria-core/game/core-scripts/esc_animation_player.gd",
        "_on_animation_finished",
        "name",
    ): "Name of the animation that triggered the callback.",
    (
        "addons/escoria-core/game/scenes/dialogs/esc_dialog_player.gd",
        "_update_dialog_manager",
        "dialog_manager_type",
    ): "Type name of the dialog manager implementation to instantiate.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_object_manager.gd",
        "register_object",
        "auto_unregister",
    ): "(optional) Automatically unregister the object when its node exits the scene tree (default: `true`).",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "is_channel_free",
        "name",
    ): "Name of the channel to inspect.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "get_running_event",
        "name",
    ): "Name of the channel whose running event should be returned.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_environment.gd",
        "is_valid_key",
        "name",
    ): "Token describing the variable name to look up.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_environment.gd",
        "get_value",
        "name",
    ): "Token describing the variable name whose value is requested.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_environment.gd",
        "assign",
        "name",
    ): "Token describing the variable name to assign.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_environment.gd",
        "define",
        "name",
    ): "Variable name to register in this scope.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_environment.gd",
        "get_at",
        "name",
    ): "Variable name to resolve at the requested scope depth.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_environment.gd",
        "assign_at",
        "name",
    ): "Token describing the variable name to modify at the requested scope depth.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_interpreter.gd",
        "look_up_variable",
        "name",
    ): "Token representing the variable name to resolve.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_script_builder.gd",
        "add_event",
        "name",
    ): "Event identifier to add to the script.",
    (
        "addons/escoria-core/game/core-scripts/esc/compiler/esc_script_builder.gd",
        "add_command",
        "name",
    ): "Command name to append to the script.",
    (
        "addons/escoria-core/game/core-scripts/esc_animation_player.gd",
        "play",
        "name",
    ): "Animation name to play.",
    (
        "addons/escoria-core/game/core-scripts/esc_animation_player.gd",
        "play_backwards",
        "name",
    ): "Animation name to play in reverse.",
    (
        "addons/escoria-core/game/core-scripts/esc_animation_player.gd",
        "has_animation",
        "name",
    ): "Animation name to test for availability.",
    (
        "addons/escoria-core/game/core-scripts/esc_animation_player.gd",
        "seek_end",
        "name",
    ): "Animation name to jump to the last frame of.",
    (
        "addons/escoria-core/game/core-scripts/esc_animation_player.gd",
        "get_length",
        "name",
    ): "Animation name whose duration should be returned.",
    (
        "addons/escoria-core/game/scenes/transitions/esc_transition_player.gd",
        "get_transition",
        "name",
    ): "Transition name whose material path should be resolved.",
    (
        "addons/escoria-core/game/scenes/transitions/esc_transition_player.gd",
        "has_transition",
        "name",
    ): "Transition name to check for availability.",
    (
        "addons/escoria-core/plugin.gd",
        "register_setting",
        "name",
    ): "Fully qualified Project Settings key to register.",
}

PARAM_OVERRIDES_BY_COMMAND = {
    (
        "addons/escoria-core/game/core-scripts/esc/commands/anim.gd",
        "anim",
        "name",
    ): "Name of the animation to start on the object.",
    (
        "addons/escoria-core/game/core-scripts/esc/commands/anim_block.gd",
        "anim_block",
        "name",
    ): "Name of the animation to play before continuing.",
    (
        "addons/escoria-core/game/core-scripts/esc/commands/dec_global.gd",
        "dec_global",
        "name",
    ): "Name of the global variable to decrement.",
    (
        "addons/escoria-core/game/core-scripts/esc/commands/inc_global.gd",
        "inc_global",
        "name",
    ): "Name of the global variable to increment.",
    (
        "addons/escoria-core/game/core-scripts/esc/commands/rand_global.gd",
        "rand_global",
        "name",
    ): "Name of the global variable that will receive the random value.",
    (
        "addons/escoria-core/game/core-scripts/esc/commands/set_global.gd",
        "set_global",
        "name",
    ): "Name of the global variable to set.",
}

PARAM_OVERRIDES_BY_SIGNAL = {
    (
        "addons/escoria-core/game/core-scripts/esc_location.gd",
        "editor_is_start_location_set",
        "node_to_ignore",
    ): "`ESCLocation` that should be ignored while validating start locations.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_globals_manager.gd",
        "global_changed",
        "global",
    ): "Key of the global that changed.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_globals_manager.gd",
        "global_changed",
        "old_value",
    ): "Value stored under the key before the change.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_globals_manager.gd",
        "global_changed",
        "new_value",
    ): "Updated value stored for the key.",
    (
        "addons/escoria-core/game/core-scripts/esc_animation_player.gd",
        "animation_finished",
        "name",
    ): "Name of the animation that completed playback.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "event_started",
        "event_name",
    ): "Name of the event whose execution has started.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "background_event_started",
        "channel_name",
    ): "Name of the background channel where the event runs.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "background_event_started",
        "event_name",
    ): "Name of the event that began on the background channel.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "event_finished",
        "return_code",
    ): "Execution result returned by the event.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "event_finished",
        "event_name",
    ): "Name of the event that just finished.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "background_event_finished",
        "return_code",
    ): "Execution result returned by the background event.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "background_event_finished",
        "event_name",
    ): "Name of the background event that finished.",
    (
        "addons/escoria-core/game/core-scripts/esc/esc_event_manager.gd",
        "background_event_finished",
        "channel_name",
    ): "Background channel where the event finished.",
    (
        "addons/escoria-core/game/core-scripts/esc/types/esc_statement.gd",
        "finished",
        "event",
    ): "`ESCStatement` representing the event whose execution completed.",
    (
        "addons/escoria-core/game/core-scripts/esc/types/esc_statement.gd",
        "finished",
        "statement",
    ): "`ESCStatement` that was running when the signal fired.",
    (
        "addons/escoria-core/game/core-scripts/esc/types/esc_statement.gd",
        "finished",
        "return_code",
    ): "Execution result code produced by the statement.",
    (
        "addons/escoria-core/game/core-scripts/esc/types/esc_statement.gd",
        "interrupted",
        "event",
    ): "`ESCStatement` representing the event whose execution was interrupted.",
    (
        "addons/escoria-core/game/core-scripts/esc/types/esc_statement.gd",
        "interrupted",
        "statement",
    ): "`ESCStatement` that was executing when the interruption occurred.",
    (
        "addons/escoria-core/game/core-scripts/esc/types/esc_statement.gd",
        "interrupted",
        "return_code",
    ): "Execution result code describing the interruption outcome.",
    (
        "addons/escoria-core/tools/logging/esc_logger.gd",
        "error_message_signal",
        "message",
    ): "Error or warning message emitted through the logger.",
}


def get_param_override(
    context_type: str,
    path: Path,
    context_name: str,
    param_name: str,
    signature_text: Optional[str] = None,
) -> Optional[str]:
    path_key = path.as_posix()
    if context_type == "function":
        if signature_text:
            key = (path_key, signature_text, param_name)
            if key in PARAM_OVERRIDES_BY_SIGNATURE:
                return PARAM_OVERRIDES_BY_SIGNATURE[key]
        key = (path_key, context_name, param_name)
        if key in PARAM_OVERRIDES_BY_FUNCTION:
            return PARAM_OVERRIDES_BY_FUNCTION[key]
    elif context_type == "command":
        key = (path_key, context_name, param_name)
        if key in PARAM_OVERRIDES_BY_COMMAND:
            return PARAM_OVERRIDES_BY_COMMAND[key]
    elif context_type == "signal":
        key = (path_key, context_name, param_name)
        if key in PARAM_OVERRIDES_BY_SIGNAL:
            return PARAM_OVERRIDES_BY_SIGNAL[key]
    return None


def strip_doc_prefix(line: str, indent: str) -> str:
    if not line.startswith(indent + "##"):
        return ""
    content = line[len(indent) + 2 :]
    if content.startswith(" "):
        content = content[1:]
    return content.rstrip("\n")


def strip_trailing_br(text: str) -> str:
    if not text:
        return text
    new_text = text
    while new_text.endswith("[br]"):
        new_text = new_text[: -4].rstrip()
    return new_text.strip()


def parse_param_bullet(raw_line: str) -> Optional[Tuple[str, str]]:
    stripped_original = raw_line.lstrip()
    if stripped_original.startswith("##"):
        content = stripped_original[2:]
    else:
        content = stripped_original
    while content.startswith("#"):
        content = content[1:]
    content = content.lstrip()
    if not content or not content.startswith(("-", "*")):
        return None
    line = strip_trailing_br(content)
    if not line:
        return None
    line = line.lstrip("-* \t")
    if not line:
        return None
    if ":" not in line:
        return None
    name_part, desc_part = line.split(":", 1)
    name = name_part.strip().strip("*").strip("`")
    desc = desc_part.strip()
    if not name:
        return None
    return name, desc


def format_type_cell(type_name: Optional[str]) -> str:
    type_str = (type_name or "").strip()
    if not type_str:
        type_str = "Variant"
    # Remove surrounding backticks if present
    if type_str.startswith("`") and type_str.endswith("`"):
        type_str = type_str[1:-1]
    parts = [part.strip() for part in type_str.split("|") if part.strip()]
    if not parts:
        parts = ["Variant"]
    return " or ".join(f"`{part}`" for part in parts)


def is_table_structure_line(raw_line: str) -> bool:
    text = strip_trailing_br(raw_line.strip())
    if not text.startswith("|"):
        return False
    inner = [part.strip() for part in text.strip().strip("|").split("|")]
    if not inner:
        return False
    first = inner[0].lower()
    return first in {"name", ":-----"}


def parse_table_row(raw_line: str) -> Optional[Dict[str, str]]:
    text = strip_trailing_br(raw_line.strip())
    if not text.startswith("|"):
        return None
    inner = [part.strip() for part in text.strip().strip("|").split("|")]
    if len(inner) != 4:
        return None
    if inner[0].lower() in {"name", ":-----"}:
        return None
    name_cell = inner[0].lstrip("\\").strip()
    return {
        "name": name_cell,
        "type": inner[1].strip("`"),
        "desc": inner[2],
        "required": inner[3].lower(),
    }


def extract_inline_return_type(text: str) -> Tuple[str, Optional[str]]:
    stripped = text.strip()
    match = re.search(r"\(`([^`]+)`\)\.?$", stripped)
    if not match:
        return text, None
    type_name = match.group(1)
    prefix = stripped[: match.start()].rstrip()
    if prefix.endswith("."):
        prefix = prefix[:-1].rstrip()
    return prefix, type_name


def normalize_whitespace(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def parse_function_signature(lines: List[str]) -> Tuple[str, str, List[Dict], str]:
    signature_text = " ".join(line.strip() for line in lines)
    signature_text = normalize_whitespace(signature_text)
    match = re.match(r"(?:static\s+)?func\s+([A-Za-z0-9_]+)\s*\((.*)\)\s*(?:->\s*([^:]+))?:", signature_text)
    func_name = ""
    params: List[Dict] = []
    return_type = "void"
    if match:
        func_name = match.group(1)
        raw_params = match.group(2).strip()
        return_type = match.group(3).strip() if match.group(3) else "void"
        if raw_params:
            params = parse_parameter_list(raw_params)
    return func_name, signature_text, params, return_type


def parse_parameter_list(params_fragment: str) -> List[Dict]:
    params: List[Dict] = []
    current = ""
    depth = 0
    for ch in params_fragment:
        if ch in "([{":
            depth += 1
            current += ch
            continue
        if ch in ")]}":
            depth = max(depth - 1, 0)
            current += ch
            continue
        if ch == "," and depth == 0:
            token = current.strip()
            if token:
                params.append(parse_parameter_token(token))
            current = ""
            continue
        current += ch
    token = current.strip()
    if token:
        params.append(parse_parameter_token(token))
    return params


def parse_parameter_token(token: str) -> Dict:
    required = True
    name_part = token
    if "=" in token:
        name_part, _ = token.split("=", 1)
        required = False
    param_type = "Variant"
    name = name_part.strip()
    if ":" in name_part:
        name_bits = name_part.split(":", 1)
        name = name_bits[0].strip()
        type_candidate = name_bits[1].strip()
        if type_candidate:
            param_type = type_candidate
    if "=" in param_type:
        param_type = param_type.split("=", 1)[0].strip()
    if "=" in name:
        name = name.split("=", 1)[0].strip()
        required = False
    name = name.lstrip("\\").strip()
    if not name:
        name = "param"
    return {"name": name, "type": param_type, "required": required}


def sanitize_description(text: str) -> str:
    text = strip_trailing_br(text)
    lowered = text.strip().lower()
    if lowered in {"none", "none."}:
        return ""
    return text


def clean_desc_text(text: str) -> str:
    if not text:
        return text
    cleaned = re.sub(r"(?:\s*None\.)+$", "", text).strip()
    return cleaned


def append_extra_text(current: str, extra: str) -> str:
    extra = strip_trailing_br(extra.strip())
    extra = extra.lstrip("-* \t")
    if not extra:
        return current
    if not current:
        return extra
    return f"{current} {extra}"


def merge_extra_rows(rows: List[Tuple[str, str, str, str]], extras: List[Tuple[str, str]]) -> List[Tuple[str, str, str, str]]:
    if not extras:
        return rows
    merged = list(rows)
    for name, desc in extras:
        name = name.strip()
        desc = desc.strip()
        if not name and not desc:
            continue
        text = " ".join(filter(None, [name, desc]))
        if merged:
            last_name, last_type, last_desc, last_required = merged[-1]
            merged[-1] = (
                last_name,
                last_type,
                append_extra_text(last_desc, text),
                last_required,
            )
        else:
            merged.append((name or "Extra", format_type_cell("Variant"), desc or DEFAULT_PARAM_DESC, "yes"))
    return merged


def reformat_function_docstring(
    block_lines: List[str],
    indent: str,
    following_lines: List[str],
    path: Path,
) -> Optional[List[str]]:
    content_lines = [strip_doc_prefix(line, indent) for line in block_lines]
    # Collect signature lines
    signature_lines: List[str] = []
    for line in following_lines:
        signature_lines.append(line)
        if line.strip().endswith(":"):
            break
    func_name, signature_text, params_info, return_type = parse_function_signature(signature_lines)

    desc_lines: List[str] = []
    params: List[Dict[str, str]] = []
    param_buffer: Optional[Dict[str, str]] = None
    return_lines: List[str] = []

    for raw_line in content_lines:
        stripped = raw_line.strip()
        if not stripped:
            continue
        if stripped.startswith("@ESC"):
            break
        lowered = stripped.lower()
        if lowered in {"[br]", "##"}:
            continue
        if lowered.startswith("#### parameters") or lowered.startswith("**parameters"):
            param_buffer = None
            continue
        if lowered.startswith("parameters"):
            param_buffer = None
            continue
        if lowered.startswith("#### returns") or lowered.startswith("**returns"):
            param_buffer = None
            continue
        if lowered.startswith("*returns*"):
            text = stripped[len("*Returns*") :].strip(" :-")
            text = strip_trailing_br(text)
            if text:
                return_lines.append(text)
            param_buffer = None
            continue
        if lowered.startswith("returns "):
            text = stripped[len("returns ") :].strip()
            text = strip_trailing_br(text)
            if text:
                return_lines.append(text)
            param_buffer = None
            continue
        if is_table_structure_line(raw_line):
            continue
        table_entry = parse_table_row(raw_line)
        if table_entry:
            entry = {"name": table_entry["name"], "desc": table_entry["desc"]}
            params.append(entry)
            param_buffer = entry
            continue
        bullet = parse_param_bullet(raw_line)
        if bullet:
            name, desc = bullet
            entry = {"name": name, "desc": desc}
            params.append(entry)
            param_buffer = entry
            continue
        if param_buffer:
            param_buffer["desc"] = append_extra_text(param_buffer.get("desc", ""), stripped)
            continue
        if return_lines:
            return_lines[-1] = append_extra_text(return_lines[-1], stripped)
            continue
        desc_lines.append(sanitize_description(raw_line))

    desc_text = " ".join(filter(None, [strip_trailing_br(line) for line in desc_lines])).strip()
    desc_text = clean_desc_text(desc_text)
    if not desc_text and return_lines:
        desc_text = return_lines[0]
        if desc_text and desc_text[0].islower():
            desc_text = desc_text[0].upper() + desc_text[1:]
    if not desc_text:
        desc_text = "No description provided."

    # Prepare parameter rows following signature order
    param_map = {entry["name"]: entry.get("desc", "") for entry in params}
    rows: List[Tuple[str, str, str, str]] = []
    for param in params_info:
        name = param["name"]
        type_name = format_type_cell(param["type"])
        required = "yes" if param["required"] else "no"
        desc = param_map.pop(name, "").strip()
        desc_key = desc.strip()
        if not desc_key or desc_key.startswith(DEFAULT_PARAM_DESC):
            override = get_param_override("function", path, func_name, name, signature_text)
            if override:
                desc = override.strip()
                desc_key = desc
        if not desc_key:
            desc = DEFAULT_PARAM_DESC
        else:
            desc = desc_key
        rows.append((name, type_name, desc, required))
    rows = merge_extra_rows(rows, list(param_map.items()))

    raw_return_desc = " ".join(return_lines).strip()
    cleaned_return_desc, inline_type = extract_inline_return_type(raw_return_desc)
    return_desc = cleaned_return_desc.strip()
    effective_declared_type = return_type
    if effective_declared_type == "void" and inline_type:
        test_desc = re.sub(r"[\.\s]+$", "", cleaned_return_desc.strip().lower())
        if test_desc not in {"", "returns nothing", "nothing"}:
            effective_declared_type = inline_type
    inferred_return_type = infer_return_type(effective_declared_type, return_desc or raw_return_desc)
    if not return_desc:
        if inferred_return_type == "void":
            return_desc = "Returns nothing."
        else:
            return_desc = f"Returns a `{inferred_return_type}` value."
    else:
        lowered = return_desc.lower()
        if lowered.startswith("returns "):
            return_desc = return_desc[8:].strip()
        elif lowered.startswith("return "):
            return_desc = return_desc[7:].strip()
        if return_desc and not return_desc.endswith("."):
            return_desc += "."
        return_desc = f"Returns {normalize_return_sentence(return_desc)}"
        if inferred_return_type and inferred_return_type != "void":
            return_desc = f"{return_desc} (`{inferred_return_type}`)"

    new_block: List[str] = []
    new_block.append(f"{indent}## {desc_text}[br]")
    new_block.append(f"{indent}## [br]")
    new_block.append(f"{indent}## #### Parameters[br]")
    new_block.append(f"{indent}## [br]")
    if rows:
        new_block.append(f"{indent}## | Name | Type | Description | Required? |[br]")
        new_block.append(f"{indent}## |:-----|:-----|:------------|:----------|[br]")
        for name, type_name, description, required in rows:
            new_block.append(f"{indent}## |{name}|{type_name}|{description}|{required}|[br]")
        new_block.append(f"{indent}## [br]")
    else:
        new_block.append(f"{indent}## None.")
        new_block.append(f"{indent}## [br]")
    new_block.append(f"{indent}## #### Returns[br]")
    new_block.append(f"{indent}## [br]")
    new_block.append(f"{indent}## {return_desc}")
    return new_block


def parse_command_signature(first_line: str) -> Tuple[str, List[Dict]]:
    command_name = ""
    fragment = ""
    signature_match = re.match(r"`\s*([A-Za-z0-9_]+)\s*\((.*)\)`", first_line.strip())
    if signature_match:
        command_name = signature_match.group(1)
        fragment = signature_match.group(2).strip()
    else:
        match = re.search(r"`[^`]*\((.*)\)`", first_line)
        if match:
            fragment = match.group(1).strip()
    if not fragment:
        return command_name, []
    params: List[Dict] = []
    current = ""
    optional_depth = 0
    for ch in fragment:
        if ch == "[":
            token = current.strip()
            if token:
                params.append(parse_command_token(token, optional_depth > 0))
            current = ""
            optional_depth += 1
            continue
        if ch == "]":
            token = current.strip()
            if token:
                params.append(parse_command_token(token, optional_depth > 0))
            current = ""
            optional_depth = max(optional_depth - 1, 0)
            continue
        if ch == ",":
            token = current.strip()
            if token:
                params.append(parse_command_token(token, optional_depth > 0))
            current = ""
            continue
        current += ch
    token = current.strip()
    if token:
        params.append(parse_command_token(token, optional_depth > 0))
    return command_name, params


def parse_command_token(token: str, is_optional: bool) -> Dict:
    token = token.strip()
    param_type = "Variant"
    name = token
    if ":" in token:
        name_part, type_part = token.split(":", 1)
        name = name_part.strip()
        type_candidate = type_part.strip()
        if type_candidate:
            param_type = type_candidate
    if "=" in param_type:
        param_type = param_type.split("=", 1)[0].strip()
    if "=" in name:
        name = name.split("=", 1)[0].strip()
        is_optional = True
    return {"name": name, "type": param_type, "required": not is_optional}


def reformat_command_docstring(
    block_lines: List[str],
    indent: str,
    path: Path,
) -> Optional[List[str]]:
    content_lines = [strip_doc_prefix(line, indent) for line in block_lines]
    if not content_lines:
        return None

    signature_line = content_lines[0].strip()
    command_name, params_info = parse_command_signature(signature_line)

    desc_lines: List[str] = []
    params: List[Dict[str, str]] = []
    param_buffer: Optional[Dict[str, str]] = None
    extra_lines: List[str] = []
    in_param_section = False

    for raw_line in content_lines[1:]:
        stripped = raw_line.strip()
        lowered = stripped.lower()
        if not stripped or lowered == "[br]":
            continue
        if stripped.startswith("@ESC"):
            break
        if lowered.startswith("#### parameters") or lowered.startswith("**parameters"):
            in_param_section = True
            param_buffer = None
            continue
        if lowered.startswith("parameters"):
            in_param_section = True
            param_buffer = None
            continue
        if in_param_section and is_table_structure_line(raw_line):
            continue
        if in_param_section:
            table_entry = parse_table_row(raw_line)
            if table_entry:
                entry = {"name": table_entry["name"], "desc": table_entry["desc"]}
                params.append(entry)
                param_buffer = entry
                continue
        bullet = parse_param_bullet(raw_line)
        if bullet and in_param_section:
            name, desc = bullet
            entry = {"name": name, "desc": desc}
            params.append(entry)
            param_buffer = entry
            continue
        if in_param_section and param_buffer:
            param_buffer["desc"] = append_extra_text(param_buffer.get("desc", ""), stripped)
            continue
        if in_param_section:
            extra_entry = strip_trailing_br(stripped)
            if extra_entry and extra_entry.strip().lower() != "none.":
                extra_lines.append(extra_entry)
            continue
        desc_lines.append(strip_trailing_br(stripped))

    desc_text = " ".join(filter(None, desc_lines)).strip()
    desc_text = clean_desc_text(desc_text)
    param_map = {entry["name"]: entry.get("desc", "") for entry in params}
    rows: List[Tuple[str, str, str, str]] = []
    for param in params_info:
        name = param["name"]
        type_name = format_type_cell(param["type"])
        required = "yes" if param["required"] else "no"
        desc = param_map.pop(name, "").strip()
        desc_key = desc.strip()
        if not desc_key or desc_key.startswith(DEFAULT_PARAM_DESC):
            override = get_param_override("command", path, command_name, name)
            if override:
                desc = override.strip()
                desc_key = desc
        if not desc_key:
            desc = DEFAULT_PARAM_DESC
        else:
            desc = desc_key
        rows.append((name, type_name, desc, required))
    rows = merge_extra_rows(rows, list(param_map.items()))

    new_block: List[str] = []
    new_block.append(f"{indent}## {signature_line}")
    new_block.append(f"{indent}##")
    if desc_text:
        new_block.append(f"{indent}## {desc_text}[br]")
    else:
        new_block.append(f"{indent}## [br]")
    new_block.append(f"{indent}## [br]")
    new_block.append(f"{indent}## #### Parameters[br]")
    new_block.append(f"{indent}## [br]")
    if rows:
        new_block.append(f"{indent}## | Name | Type | Description | Required? |[br]")
        new_block.append(f"{indent}## |:-----|:-----|:------------|:----------|[br]")
        for name, type_name, description, required in rows:
            new_block.append(f"{indent}## |{name}|{type_name}|{description}|{required}|[br]")
        new_block.append(f"{indent}## [br]")
        for line in extra_lines:
            if line:
                new_block.append(f"{indent}## {line}[br]")
    else:
        new_block.append(f"{indent}## None.")
        new_block.append(f"{indent}## [br]")
        for line in extra_lines:
            if line:
                new_block.append(f"{indent}## {line}[br]")
    return new_block


def normalize_return_sentence(text: str) -> str:
    text = text.strip()
    if not text:
        return text
    first_word = text.split(" ", 1)[0].lower()
    if first_word in {"the", "a", "an"} and len(text) > 1:
        text = text[0].lower() + text[1:]
    return text


def infer_return_type(declared_type: str, return_desc: str) -> str:
    declared_type = (declared_type or "").strip()
    if declared_type and declared_type != "void":
        return declared_type
    if not return_desc:
        return declared_type or "void"
    lowered = return_desc.lower()
    if "nothing" in lowered or "no value" in lowered:
        return "void"
    if "true" in lowered or "false" in lowered:
        return "bool"
    if "array" in lowered:
        return "Array"
    if "dictionary" in lowered:
        return "Dictionary"
    if "string" in lowered:
        return "String"
    if "float" in lowered:
        return "float"
    if "int" in lowered:
        return "int"
    if "vector2" in lowered:
        return "Vector2"
    if "vector3" in lowered:
        return "Vector3"
    return "Variant"


def parse_signal_signature(signal_line: str) -> Tuple[str, List[str]]:
    match = re.match(r"\s*signal\s+([A-Za-z0-9_]+)\s*(?:\((.*)\))?", signal_line)
    if not match:
        return "", []
    signal_name = match.group(1)
    params_fragment = (match.group(2) or "").strip()
    if not params_fragment:
        return signal_name, []
    params = []
    current = ""
    depth = 0
    for ch in params_fragment:
        if ch == "," and depth == 0:
            token = current.strip()
            if token:
                params.append(token)
            current = ""
            continue
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth = max(depth - 1, 0)
        current += ch
    token = current.strip()
    if token:
        params.append(token)
    names = []
    for token in params:
        if ":" in token:
            token = token.split(":", 1)[0].strip()
        if "=" in token:
            token = token.split("=", 1)[0].strip()
        names.append(token)
    return signal_name, names


def reformat_signal_docstring(
    block_lines: List[str],
    indent: str,
    signal_line: str,
    path: Path,
) -> Optional[List[str]]:
    content_lines = [strip_doc_prefix(line, indent) for line in block_lines]
    if not content_lines:
        return None

    desc_lines: List[str] = []
    params: List[Dict[str, str]] = []
    param_buffer: Optional[Dict[str, str]] = None
    in_param_section = False

    for raw_line in content_lines:
        stripped = raw_line.strip()
        lowered = stripped.lower()
        if not stripped or lowered == "[br]":
            continue
        if lowered.startswith("#### parameters") or lowered.startswith("**parameters"):
            in_param_section = True
            param_buffer = None
            continue
        if lowered.startswith("parameters"):
            in_param_section = True
            param_buffer = None
            continue
        if lowered.startswith("#### returns") or lowered.startswith("**returns"):
            in_param_section = False
            continue
        if in_param_section and is_table_structure_line(raw_line):
            continue
        if in_param_section:
            table_entry = parse_table_row(raw_line)
            if table_entry:
                entry = {"name": table_entry["name"], "desc": table_entry["desc"]}
                params.append(entry)
                param_buffer = entry
                continue
        bullet = parse_param_bullet(raw_line)
        if bullet and in_param_section:
            name, desc = bullet
            entry = {"name": name, "desc": desc}
            params.append(entry)
            param_buffer = entry
            continue
        if in_param_section and param_buffer:
            param_buffer["desc"] = append_extra_text(param_buffer.get("desc", ""), stripped)
            continue
        if in_param_section:
            continue
        desc_lines.append(strip_trailing_br(stripped))

    desc_text = " ".join(filter(None, desc_lines)).strip()
    desc_text = clean_desc_text(desc_text)
    if not desc_text:
        desc_text = "No description provided."

    signal_name, signature_params = parse_signal_signature(signal_line)
    param_map = {entry["name"]: entry.get("desc", "") for entry in params}
    rows: List[Tuple[str, str, str, str]] = []
    for param_name in signature_params:
        desc = param_map.pop(param_name, "").strip()
        desc_key = desc.strip()
        if not desc_key or desc_key.startswith(DEFAULT_PARAM_DESC):
            override = get_param_override("signal", path, signal_name, param_name)
            if override:
                desc = override.strip()
                desc_key = desc
        if not desc_key:
            desc = DEFAULT_PARAM_DESC
        else:
            desc = desc_key
        rows.append((param_name, format_type_cell(None), desc, "yes"))
    for extra_name, desc in param_map.items():
        name = extra_name.strip()
        if not name:
            continue
        cleaned_desc = desc.strip()
        if not cleaned_desc or cleaned_desc.startswith(DEFAULT_PARAM_DESC):
            override = get_param_override("signal", path, signal_name, name)
            if override:
                cleaned_desc = override
        if not cleaned_desc:
            cleaned_desc = DEFAULT_PARAM_DESC
        rows.append((name, format_type_cell(None), cleaned_desc, "yes"))

    new_block: List[str] = []
    new_block.append(f"{indent}## {desc_text}[br]")
    new_block.append(f"{indent}## [br]")
    new_block.append(f"{indent}## #### Parameters[br]")
    new_block.append(f"{indent}## [br]")
    if rows:
        new_block.append(f"{indent}## | Name | Type | Description | Required? |[br]")
        new_block.append(f"{indent}## |:-----|:-----|:------------|:----------|[br]")
        for name, type_name, description, required in rows:
            new_block.append(f"{indent}## |{name}|{type_name}|{description}|{required}|[br]")
        new_block.append(f"{indent}## [br]")
    else:
        new_block.append(f"{indent}## None.")
        new_block.append(f"{indent}## [br]")
    return new_block


def process_file(path: Path) -> Tuple[str, bool]:
    text = path.read_text()
    lines = text.splitlines()
    i = 0
    changed = False
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()
        if not stripped.startswith("##") or stripped.startswith("## @"):
            i += 1
            continue
        indent_match = re.match(r"^(\s*)##", line)
        if not indent_match:
            i += 1
            continue
        indent = indent_match.group(1)
        block_start = i
        block_end = i
        while block_end < len(lines):
            stripped_block = lines[block_end].lstrip()
            if not stripped_block.startswith("##") or stripped_block.startswith("## @"):
                break
            block_end += 1
        block_lines = lines[block_start:block_end]

        # Determine context
        k = block_end
        signature_lines: List[str] = []
        while k < len(lines):
            candidate = lines[k].strip()
            if candidate == "":
                k += 1
                continue
            if candidate.startswith("## @"):
                k += 1
                continue
            if candidate.startswith("##"):
                break
            break
        if k >= len(lines):
            i = block_end
            continue
        next_line = lines[k]

        if re.match(r"\s*(?:static\s+)?func\b", next_line):
            signature_lines = []
            sig_index = k
            while sig_index < len(lines):
                signature_lines.append(lines[sig_index].strip())
                if lines[sig_index].strip().endswith(":"):
                    break
                sig_index += 1
            new_block = reformat_function_docstring(block_lines, indent, signature_lines, path)
            if new_block:
                lines[block_start:block_end] = new_block
                changed = True
                block_end = block_start + len(new_block)
                i = block_end
                continue
        elif "extends ESCBaseCommand" in next_line:
            new_block = reformat_command_docstring(block_lines, indent, path)
            if new_block:
                lines[block_start:block_end] = new_block
                changed = True
                block_end = block_start + len(new_block)
                i = block_end
                continue
        elif next_line.strip().startswith("signal "):
            new_block = reformat_signal_docstring(block_lines, indent, next_line.strip(), path)
            if new_block:
                lines[block_start:block_end] = new_block
                changed = True
                block_end = block_start + len(new_block)
                i = block_end
                continue
        i = block_end
    new_text = "\n".join(lines)
    if text.endswith("\n"):
        new_text += "\n"
    return new_text, changed


def main() -> None:
    total_changed = 0
    for path in ROOT.rglob("*.gd"):
        new_text, changed = process_file(path)
        if changed:
            path.write_text(new_text)
            total_changed += 1


if __name__ == "__main__":
    main()
