#!/usr/bin/env python3
"""
Utility to normalize GDScript docstrings in Escoria to the format described in AGENTS.md.

This script focuses on reformatting existing docstrings without discarding information.
It reconstructs parameter tables, enforces the `[br]` line break tokens, wraps type names
in backticks, and preserves warnings / notes. The primary target is public-facing methods
and command classes under `addons/escoria-core`.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


DOC_PREFIX = "##"
BR_TOKEN = "[br]"
PARAM_TABLE_HEADER = [
    "| Name | Type | Description | Required? |",
    "|:-----|:-----|:------------|:----------|",
]


def strip_prefix(text: str, prefix: str) -> str:
    if text.startswith(prefix):
        return text[len(prefix) :]
    return text


def strip_doc_line(line: str, indent: str) -> str:
    if not line.startswith(indent):
        # If indentation is inconsistent, fall back to lstrip to avoid losing content.
        line = line.lstrip()
    else:
        line = line[len(indent) :]
    content = strip_prefix(line, DOC_PREFIX).lstrip()
    while content.startswith("#"):
        content = content[1:].lstrip()
    return content


def strip_br_suffix(text: str) -> Tuple[str, bool]:
    """
    Remove a trailing `[br]` token from the given string.
    Returns a tuple of (new_text, removed_br).
    """
    updated = text.rstrip()
    if updated.endswith(BR_TOKEN):
        updated = updated[: -len(BR_TOKEN)].rstrip()
        return updated, True
    return text, False


def ensure_br(text: str) -> str:
    stripped, had_br = strip_br_suffix(text)
    if had_br:
        return stripped + f"{BR_TOKEN}"
    return stripped


def ensure_type_backticks(type_text: str) -> str:
    clean = type_text.strip()
    if not clean:
        return "`Variant`"
    if clean.startswith("`") and clean.endswith("`"):
        return clean
    return f"`{clean}`"


def collapse_spaces(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip())


@dataclass
class ParameterDoc:
    name: str
    type_name: str
    description: str
    required: str

    def ensure_defaults(self) -> None:
        if not self.type_name:
            self.type_name = "Variant"
        if not self.description:
            self.description = "Description not provided."
        if self.required not in {"yes", "no"}:
            self.required = "yes"


@dataclass
class ReturnDoc:
    type_name: str
    description: str

    def ensure_defaults(self) -> None:
        if not self.type_name:
            self.type_name = "Variant"
        if not self.description:
            self.description = "Description not provided."


@dataclass
class DocstringData:
    description_lines: List[str] = field(default_factory=list)
    parameters: Dict[str, ParameterDoc] = field(default_factory=dict)
    returns: Optional[ReturnDoc] = None
    notes_lines: List[str] = field(default_factory=list)
    extra_sections: Dict[str, List[str]] = field(default_factory=dict)
    trailer_lines: List[str] = field(default_factory=list)


def parse_section_lines(raw_lines: Sequence[str]) -> Dict[str, List[str]]:
    sections: Dict[str, List[str]] = {"description": []}
    current = "description"

    for line in raw_lines:
        raw = line.strip()
        normalized = raw
        if normalized.endswith(BR_TOKEN):
            normalized = normalized[: -len(BR_TOKEN)].rstrip()
        if normalized:
            normalized_lower = normalized.lower()
            matched = False
            for key, tokens in SECTION_TOKENS.items():
                for token in tokens:
                    token_lower = token.lower()
                    rest = ""
                    if normalized_lower == token_lower:
                        matched = True
                    elif normalized_lower.startswith(token_lower + " "):
                        rest = normalized[len(token):].lstrip(" :-")
                        matched = True
                    elif normalized_lower.startswith(token_lower + ":"):
                        rest = normalized[len(token):].lstrip(" :-")
                        matched = True
                    elif normalized_lower.startswith(token_lower + "-"):
                        rest = normalized[len(token):].lstrip(" :-")
                        matched = True
                    if matched:
                        current = key
                        sections.setdefault(current, [])
                        if rest:
                            sections[current].append(rest)
                        break
                if matched:
                    break
            if matched:
                continue
        sections.setdefault(current, []).append(line)

    return sections


def clean_doc_lines(lines: Iterable[str]) -> List[str]:
    cleaned: List[str] = []
    for line in lines:
        text = line.strip()
        if not text:
            cleaned.append("")
            continue
        # Remove `[br]` tokens because we'll re-apply them later.
        text, _ = strip_br_suffix(text)
        cleaned.append(text)
    # Trim leading / trailing blank entries.
    while cleaned and not cleaned[0]:
        cleaned.pop(0)
    while cleaned and not cleaned[-1]:
        cleaned.pop()
    return cleaned


def parse_parameter_table(lines: Sequence[str]) -> Dict[str, ParameterDoc]:
    params: Dict[str, ParameterDoc] = {}
    for line in lines:
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = [cell.strip() for cell in stripped.split("|")[1:-1]]
        if len(cells) != 4:
            continue
        if cells[0].lower() == "name" and cells[1].lower().startswith("type"):
            continue
        if all(cell and all(ch in ":-" for ch in cell) for cell in cells):
            continue
        name = cells[0]
        type_name = cells[1]
        description = cells[2]
        required = cells[3].lower()
        params[name] = ParameterDoc(
            name=name,
            type_name=type_name.strip("`"),
            description=description,
            required=required,
        )
    return params


def parse_parameter_bullets(lines: Sequence[str]) -> Dict[str, ParameterDoc]:
    params: Dict[str, ParameterDoc] = {}
    current: Optional[ParameterDoc] = None

    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        text, _ = strip_br_suffix(stripped)
        text = text.strip()
        if not text:
            continue
        lowered = text.lower()
        if lowered.startswith("this method does not accept parameters") or lowered.startswith("this command does not accept parameters"):
            return {}

        if text.startswith("-"):
            content = text[1:].strip()
            if ":" in content:
                name_part, desc_part = content.split(":", 1)
                name = re.sub(r"[`\*]", "", name_part).strip()
                description = desc_part.strip()
            else:
                name = re.sub(r"[`\*]", "", content).strip()
                description = ""
            current = ParameterDoc(
                name=name,
                type_name="",
                description=description,
                required="yes",
            )
            params[name] = current
            continue

        if current:
            if current.description:
                current.description += " " + text
            else:
                current.description = text

    return params


def parse_parameters_section(lines: Sequence[str]) -> Dict[str, ParameterDoc]:
    if any(line.strip().startswith("|") for line in lines):
        return parse_parameter_table(lines)
    return parse_parameter_bullets(lines)


RETURN_PATTERN = re.compile(
    r"^`?(?P<type>[A-Za-z0-9_\.]+)`?\s*(?:—|-)\s*(?P<desc>.+)$"
)
RETURN_MARKER_RE = re.compile(r"\*+returns?\*+", re.IGNORECASE)


def parse_return_section(lines: Sequence[str]) -> Optional[ReturnDoc]:
    cleaned: List[str] = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        text, _ = strip_br_suffix(stripped)
        text = text.strip()
        if not text:
            continue
        text = RETURN_MARKER_RE.sub("", text).strip()
        cleaned.append(collapse_spaces(text))
    if not cleaned:
        return None

    first_line = cleaned[0]
    match = RETURN_PATTERN.match(first_line)
    if match:
        return ReturnDoc(match.group("type"), match.group("desc"))

    if first_line.lower().startswith("returns"):
        desc = first_line.split(":", 1)[1].strip() if ":" in first_line else first_line
        return ReturnDoc("", desc)

    # Fall back to treating the line as description only.
    return ReturnDoc("", cleaned[0])


WARNING_PREFIXES = ("**Warning**", "**Note**", "**Notes**", "**Warning:**", "**Note:**")
SECTION_TOKENS = {
    "parameters": ["#### parameters", "**parameters**", "*parameters*", "parameters", "parameters:"],
    "returns": ["#### returns", "**returns**", "*returns*", "returns:", "return:", "return value", "return value:"],
    "notes": ["#### notes", "**notes**", "*notes*", "notes", "notes:"],
}


def extract_description_and_notes(lines: Sequence[str]) -> Tuple[List[str], List[str]]:
    description: List[str] = []
    notes: List[str] = []

    for line in clean_doc_lines(lines):
        if any(line.startswith(prefix) for prefix in WARNING_PREFIXES):
            notes.append(line)
        elif line.startswith("@"):
            notes.append(line)
        else:
            description.append(line)

    return description, notes


def extract_note_lines(lines: Sequence[str]) -> Tuple[List[str], List[str]]:
    notes: List[str] = []
    filtered: List[str] = []
    note_active = False
    for line in lines:
        stripped = line.strip()
        if not stripped:
            filtered.append(line)
            note_active = False
            continue
        text, _ = strip_br_suffix(stripped)
        text = text.strip()
        if not text:
            filtered.append(line)
            note_active = False
            continue
        if note_active:
            notes[-1] += f" {text}"
            continue
        if any(text.startswith(prefix) for prefix in WARNING_PREFIXES):
            notes.append(text)
            note_active = True
            continue
        if text.startswith("@"):
            notes.append(text)
            note_active = False
            continue
        filtered.append(line)
    return notes, filtered


def parse_docstring(raw_lines: Sequence[str]) -> DocstringData:
    sections = parse_section_lines(raw_lines)
    description_lines, note_lines = extract_description_and_notes(sections.get("description", []))
    data = DocstringData(description_lines=description_lines, notes_lines=note_lines)

    if "parameters" in sections:
        param_notes, param_lines = extract_note_lines(sections["parameters"])
        data.notes_lines.extend(param_notes)
        data.parameters = parse_parameters_section(param_lines)
    if "returns" in sections:
        data.returns = parse_return_section(sections["returns"])
    if "notes" in sections:
        note_desc, note_warn = extract_description_and_notes(sections["notes"])
        data.notes_lines.extend(note_desc)
        data.notes_lines.extend(note_warn)

    extra_keys = {
        key
        for key in sections.keys()
        if key not in {"description", "parameters", "returns", "notes"}
    }
    for key in extra_keys:
        data.extra_sections[key] = clean_doc_lines(sections[key])

    return data


FUNC_DEF_RE = re.compile(r"func\s+([A-Za-z0-9_]+)")


def get_function_signature(lines: Sequence[str], start_index: int) -> Tuple[Optional[str], Optional[str]]:
    """
    Returns (function_name, signature_text) starting at `start_index`.
    The caller should ensure that lines[start_index] is part of a `func` definition.
    """
    if start_index >= len(lines):
        return None, None

    idx = start_index
    while idx < len(lines) and not lines[idx].strip():
        idx += 1

    if idx >= len(lines):
        return None, None

    first_line = lines[idx]
    match = FUNC_DEF_RE.search(first_line)
    if not match:
        return None, None
    name = match.group(1)

    signature_parts = [first_line.rstrip("\n")]
    open_parens = first_line.count("(") - first_line.count(")")
    while idx + 1 < len(lines) and (open_parens > 0 or not first_line.rstrip().endswith(":")):
        idx += 1
        next_line = lines[idx].rstrip("\n")
        signature_parts.append(next_line)
        open_parens += next_line.count("(") - next_line.count(")")
        first_line = next_line
        if open_parens <= 0 and next_line.rstrip().endswith(":"):
            break

    signature_text = " ".join(part.strip() for part in signature_parts)
    return name, signature_text


TYPE_HINT_RE = re.compile(r":\s*([^=\s]+)")


def parse_func_parameters(signature_text: str) -> List[ParameterDoc]:
    if "(" not in signature_text or ")" not in signature_text:
        return []
    inner = signature_text[signature_text.index("(") + 1 : signature_text.rfind(")")]
    # Remove trailing comments.
    inner = inner.split("#", 1)[0]

    params: List[ParameterDoc] = []
    current = ""
    depth = 0
    for char in inner:
        if char == "(":
            depth += 1
            current += char
        elif char == ")":
            depth = max(depth - 1, 0)
            current += char
        elif char == "," and depth == 0:
            token = current.strip()
            if token:
                params.append(_build_param_from_token(token))
            current = ""
        else:
            current += char

    token = current.strip()
    if token:
        params.append(_build_param_from_token(token))

    return params


DEFAULT_VALUE_RE = re.compile(r"=\s*(.+)$")


def _build_param_from_token(token: str) -> ParameterDoc:
    name = token
    type_name = ""
    required = "yes"
    description = ""

    default_match = DEFAULT_VALUE_RE.search(token)
    if default_match:
        required = "no"
        token = token[: default_match.start()].strip()

    if ":" in token:
        name_part, type_part = token.split(":", 1)
        name = name_part.strip()
        type_name = collapse_spaces(type_part)
    else:
        name = token.strip()

    if not type_name:
        type_name = "Variant"

    return ParameterDoc(
        name=name,
        type_name=type_name,
        description=description,
        required=required,
    )


RETURN_TYPE_RE = re.compile(r"->\s*([^:\s]+)")


def parse_return_from_signature(signature_text: str) -> Optional[str]:
    match = RETURN_TYPE_RE.search(signature_text)
    if match:
        return collapse_spaces(match.group(1))
    return None


COMMAND_EXTENDS_RE = re.compile(r"extends\s+ESCBaseCommand")


def detect_command_class(context_lines: Sequence[str], start_index: int) -> bool:
    idx = start_index
    while idx < len(context_lines) and not context_lines[idx].strip():
        idx += 1
    if idx >= len(context_lines):
        return False
    return COMMAND_EXTENDS_RE.search(context_lines[idx]) is not None


COMMAND_SIGNATURE_RE = re.compile(r"`([^`]+)`")


def parse_command_signature(line: str) -> Tuple[str, str, List[ParameterDoc]]:
    """
    Parse a command signature line like
    `anim(object: String[, reverse: Boolean])`
    and return (signature_text, command_name, parameters).
    """
    match = COMMAND_SIGNATURE_RE.search(line)
    if not match:
        return "", "", []
    signature = match.group(1)
    if "(" not in signature:
        return signature.strip(), signature.strip(), []
    name = signature[: signature.index("(")].strip()
    params_text = signature[signature.index("(") + 1 : signature.rfind(")")]

    params: List[ParameterDoc] = []
    current = ""
    depth = 0
    for char in params_text:
        if char == "[":
            if current.strip():
                params.append(_build_command_param(current.strip(), optional=(depth > 0)))
                current = ""
            depth += 1
        elif char == "]":
            if current.strip():
                params.append(_build_command_param(current.strip(), optional=True))
                current = ""
            depth = max(depth - 1, 0)
        elif char == "," and depth == 0:
            if current.strip():
                params.append(_build_command_param(current.strip(), optional=False))
                current = ""
        else:
            current += char

    if current.strip():
        params.append(_build_command_param(current.strip(), optional=(depth > 0)))

    # Filter out empty entries introduced by commas.
    params = [param for param in params if param.name]
    return signature.strip(), name, params


def _build_command_param(token: str, optional: bool) -> ParameterDoc:
    token = token.strip()
    required = "no" if optional else "yes"
    if token.startswith(","):
        token = token[1:].strip()

    if ":" in token:
        name_part, type_part = token.split(":", 1)
        name = name_part.strip()
        type_name = collapse_spaces(type_part)
    else:
        name = collapse_spaces(token)
        type_name = "Variant"

    return ParameterDoc(
        name=name,
        type_name=type_name,
        description="",
        required=required,
    )


def merge_parameter_details(
    signature_params: List[ParameterDoc],
    existing_params: Dict[str, ParameterDoc],
) -> List[ParameterDoc]:
    merged: List[ParameterDoc] = []
    for param in signature_params:
        existing = existing_params.get(param.name)
        if existing:
            description = existing.description or param.description
            type_name = param.type_name or existing.type_name
            required = param.required or existing.required
            merged.append(
                ParameterDoc(
                    name=param.name,
                    type_name=type_name,
                    description=description,
                    required=required,
                )
            )
        else:
            merged.append(param)

    # Include any existing parameters we could not match (to avoid data loss).
    for name, param in existing_params.items():
        if name not in {p.name for p in merged}:
            merged.append(param)

    for param in merged:
        param.ensure_defaults()

    return merged


def merge_return_details(
    existing: Optional[ReturnDoc],
    fallback_type: Optional[str],
) -> ReturnDoc:
    if existing:
        existing.ensure_defaults()
        if fallback_type and (not existing.type_name or existing.type_name == "Variant"):
            existing.type_name = fallback_type
        if existing.type_name == "void" and existing.description == "Description not provided.":
            existing.description = "No value returned."
        return existing

    type_name = fallback_type or "Variant"
    default_description = "No value returned." if type_name == "void" else "Description not provided."
    doc = ReturnDoc(
        type_name=type_name,
        description=default_description,
    )
    doc.ensure_defaults()
    return doc


def format_description_lines(lines: Sequence[str], indent: str) -> List[str]:
    if not lines:
        lines = ["Description not provided."]
    formatted: List[str] = []
    for line in lines:
        formatted.append(f"{indent}{DOC_PREFIX} {line}{BR_TOKEN}")
    return formatted


def format_blank_line(indent: str) -> List[str]:
    return [f"{indent}{DOC_PREFIX} {BR_TOKEN}"]


def format_parameters_section(parameters: List[ParameterDoc], indent: str) -> List[str]:
    output: List[str] = []
    output.append(f"{indent}{DOC_PREFIX} #### Parameters{BR_TOKEN}")
    output.extend(format_blank_line(indent))
    if parameters:
        output.extend(f"{indent}{DOC_PREFIX} {line}{BR_TOKEN}" for line in PARAM_TABLE_HEADER)
        for param in parameters:
            output.append(
                f"{indent}{DOC_PREFIX} |{param.name}|{ensure_type_backticks(param.type_name)}|{param.description}|{param.required}|{BR_TOKEN}"
            )
    else:
        output.append(f"{indent}{DOC_PREFIX} This method does not accept parameters.{BR_TOKEN}")
    return output


def format_returns_section(return_doc: ReturnDoc, indent: str) -> List[str]:
    output: List[str] = []
    output.append(f"{indent}{DOC_PREFIX} #### Returns{BR_TOKEN}")
    output.extend(format_blank_line(indent))
    description = return_doc.description.strip()
    if description and not description.endswith("."):
        description += "."
    output.append(
        f"{indent}{DOC_PREFIX} {ensure_type_backticks(return_doc.type_name)} — {description}"
    )
    return output


def format_notes_section(notes: Sequence[str], indent: str) -> List[str]:
    if not notes:
        return []
    output: List[str] = []
    output.append(f"{indent}{DOC_PREFIX} #### Notes{BR_TOKEN}")
    output.extend(format_blank_line(indent))
    for note in notes:
        output.append(f"{indent}{DOC_PREFIX} {note}{BR_TOKEN}")
    return output


def format_extra_sections(extra: Dict[str, List[str]], indent: str) -> List[str]:
    lines: List[str] = []
    for name, contents in extra.items():
        title = name.title()
        lines.append(f"{indent}{DOC_PREFIX} #### {title}{BR_TOKEN}")
        lines.extend(format_blank_line(indent))
        if contents:
            for entry in contents:
                lines.append(f"{indent}{DOC_PREFIX} {entry}{BR_TOKEN}")
        else:
            lines.append(f"{indent}{DOC_PREFIX} {BR_TOKEN}")
    return lines


def rebuild_function_docstring(
    raw_lines: Sequence[str],
    indent: str,
    surrounding_lines: Sequence[str],
    context_index: int,
) -> List[str]:
    data = parse_docstring(raw_lines)
    func_name, signature_text = get_function_signature(surrounding_lines, context_index)
    signature_params: List[ParameterDoc] = []
    return_type_hint: Optional[str] = None

    if signature_text:
        signature_params = parse_func_parameters(signature_text)
        return_type_hint = parse_return_from_signature(signature_text)

    parameters = merge_parameter_details(signature_params, data.parameters)
    return_doc = merge_return_details(data.returns, return_type_hint)

    rebuilt: List[str] = []
    rebuilt.extend(format_description_lines(data.description_lines, indent))
    rebuilt.extend(format_blank_line(indent))
    rebuilt.extend(format_parameters_section(parameters, indent))
    rebuilt.extend(format_blank_line(indent))
    rebuilt.extend(format_returns_section(return_doc, indent))
    notes = data.notes_lines
    extra = data.extra_sections
    if notes:
        rebuilt.extend(format_blank_line(indent))
        rebuilt.extend(format_notes_section(notes, indent))
    if extra:
        rebuilt.extend(format_blank_line(indent))
        rebuilt.extend(format_extra_sections(extra, indent))
    return rebuilt


def rebuild_command_docstring(
    raw_lines: Sequence[str],
    indent: str,
) -> List[str]:
    data = parse_docstring(raw_lines)

    cleaned_lines = clean_doc_lines(raw_lines)
    first_nonempty = next((line for line in cleaned_lines if line), "")
    signature_text, command_name, signature_params = parse_command_signature(first_nonempty)
    if not signature_text:
        return rebuild_generic_docstring(raw_lines, indent)
    parameters = merge_parameter_details(signature_params, data.parameters)

    rebuilt: List[str] = []

    # Recreate the brief description with no trailing [br] per requirement.
    if signature_text:
        rebuilt.append(f"{indent}{DOC_PREFIX} `{signature_text}`")
    else:
        # Preserve the first line even if no signature detected.
        original_first = raw_lines[0].strip()
        rebuilt.append(f"{indent}{DOC_PREFIX} {strip_prefix(original_first, DOC_PREFIX).strip()}")

    rebuilt.append(f"{indent}{DOC_PREFIX}")
    # Append the remaining description lines (skip the first signature line).
    signature_line = f"`{signature_text}`" if signature_text else ""
    description_lines = [line for line in data.description_lines if line != signature_line]
    if not description_lines:
        # If removing the signature removed everything, fall back to original description lines.
        description_lines = data.description_lines
    description_lines = [line for line in description_lines if line]
    rebuilt.extend(format_description_lines(description_lines, indent))
    rebuilt.extend(format_blank_line(indent))
    rebuilt.extend(format_parameters_section(parameters, indent))
    if data.notes_lines or data.extra_sections or data.returns:
        rebuilt.extend(format_blank_line(indent))
    if data.notes_lines:
        rebuilt.extend(format_notes_section(data.notes_lines, indent))
    if data.returns:
        rebuilt.extend(format_returns_section(data.returns, indent))
    if data.extra_sections:
        rebuilt.extend(format_blank_line(indent))
        rebuilt.extend(format_extra_sections(data.extra_sections, indent))
    if data.trailer_lines:
        rebuilt.extend(data.trailer_lines)
    return rebuilt


def rebuild_generic_docstring(raw_lines: Sequence[str], indent: str) -> List[str]:
    data = parse_docstring(raw_lines)
    rebuilt: List[str] = []
    rebuilt.extend(format_description_lines(data.description_lines, indent))
    if data.parameters:
        rebuilt.extend(format_blank_line(indent))
        rebuilt.extend(format_parameters_section(list(data.parameters.values()), indent))
    if data.returns:
        rebuilt.extend(format_blank_line(indent))
        rebuilt.extend(format_returns_section(data.returns, indent))
    if data.notes_lines:
        rebuilt.extend(format_blank_line(indent))
        rebuilt.extend(format_notes_section(data.notes_lines, indent))
    if data.extra_sections:
        rebuilt.extend(format_blank_line(indent))
        rebuilt.extend(format_extra_sections(data.extra_sections, indent))
    return rebuilt


def find_next_code_line(lines: Sequence[str], start_index: int) -> int:
    idx = start_index
    while idx < len(lines):
        stripped = lines[idx].strip()
        if not stripped:
            idx += 1
            continue
        if stripped.startswith("#"):
            idx += 1
            continue
        break
    return idx


def collect_docstring_block(
    lines: Sequence[str], start_index: int
) -> Tuple[int, List[str], List[str], str]:
    indent = re.match(r"\s*", lines[start_index]).group(0)
    original_block: List[str] = []
    content_block: List[str] = []
    idx = start_index
    while idx < len(lines):
        line = lines[idx]
        stripped = line.lstrip()
        if not stripped.startswith(DOC_PREFIX):
            break
        original_block.append(line.rstrip("\n"))
        content_block.append(strip_doc_line(line.rstrip("\n"), indent))
        idx += 1
    return idx, original_block, content_block, indent


def rebuild_docstring(
    raw_block: List[str],
    indent: str,
    full_lines: Sequence[str],
    context_index: int,
) -> List[str]:
    next_code_idx = find_next_code_line(full_lines, context_index)
    if next_code_idx >= len(full_lines):
        return [f"{indent}{DOC_PREFIX} {line}" for line in raw_block]

    next_line = full_lines[next_code_idx].strip()
    if next_line.startswith("func "):
        return rebuild_function_docstring(raw_block, indent, full_lines, next_code_idx)
    if next_line.startswith("class_name") or next_line.startswith("extends"):
        if detect_command_class(full_lines, next_code_idx):
            return rebuild_command_docstring(raw_block, indent)
        return rebuild_generic_docstring(raw_block, indent)

    return rebuild_generic_docstring(raw_block, indent)


def process_file(path: Path) -> bool:
    original_lines = path.read_text(encoding="utf-8").splitlines()
    new_lines: List[str] = []
    idx = 0
    changed = False

    while idx < len(original_lines):
        line = original_lines[idx]
        stripped = line.lstrip()
        if stripped.startswith(DOC_PREFIX):
            block_end, original_block, content_block, indent = collect_docstring_block(
                original_lines, idx
            )
            rebuilt = rebuild_docstring(content_block, indent, original_lines, block_end)
            new_lines.extend(rebuilt)
            idx = block_end
            if not changed:
                if len(original_block) != len(rebuilt):
                    changed = True
                else:
                    for raw_line, new_line in zip(original_block, rebuilt):
                        if raw_line != new_line:
                            changed = True
                            break
            continue

        new_lines.append(line)
        idx += 1

    if changed:
        path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
    return changed


def iter_gd_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*.gd"):
        if path.is_file():
            yield path


def main() -> None:
    parser = argparse.ArgumentParser(description="Normalize GDScript docstrings per AGENTS.md.")
    parser.add_argument(
        "paths",
        nargs="*",
        default=["addons/escoria-core"],
        help="Directories or files to process (default: addons/escoria-core).",
    )
    args = parser.parse_args()

    targets: List[Path] = []
    for value in args.paths:
        path = Path(value)
        if path.is_file():
            targets.append(path)
        elif path.is_dir():
            targets.extend(iter_gd_files(path))

    processed = 0
    changed = 0
    for path in sorted(set(targets)):
        processed += 1
        if process_file(path):
            changed += 1

    print(f"Processed {processed} files; updated {changed}.")


if __name__ == "__main__":
    main()
