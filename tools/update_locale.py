#!/usr/bin/env python3

import ast
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
LOCALE_DIR = ROOT / "locale"
POT_FILE = LOCALE_DIR / "jc_special.pot"

SOURCE_FILES = sorted(
  path for path in ROOT.glob("*.lua")
  if path.name != "init.lua"
)


def po_lines(field, value):
  escaped = (
    value
    .replace("\\", "\\\\")
    .replace('"', '\\"')
    .replace("\t", "\\t")
    .replace("\r", "\\r")
    .replace("\n", "\\n")
  )

  return [field + ' "' + escaped + '"']


def parse_lua_string(source, start):
  if start >= len(source) or source[start] != '"':
    return None, start

  end = start + 1
  escaped = False

  while end < len(source):
    char = source[end]

    if escaped:
      escaped = False
      end += 1
      continue

    if char == "\\":
      escaped = True
      end += 1
      continue

    if char == '"':
      literal = source[start:end + 1]

      try:
        value = ast.literal_eval(literal)
      except (SyntaxError, ValueError):
        return None, end + 1

      return value, end + 1

    end += 1

  return None, end


def skip_lua_space(source, position):
  while position < len(source):
    if source[position].isspace():
      position += 1
      continue

    if source.startswith("--[[", position):
      end = source.find("]]", position + 4)

      if end == -1:
        return len(source)

      position = end + 2
      continue

    if source.startswith("--", position):
      end = source.find("\n", position + 2)

      if end == -1:
        return len(source)

      position = end + 1
      continue

    break

  return position


def extract_s_strings(source):
  results = []

  pattern = re.compile(r"\bS\s*\(")

  for match in pattern.finditer(source):
    position = skip_lua_space(source, match.end())

    value, position = parse_lua_string(source, position)

    if value is None:
      continue

    parts = [value]

    position = skip_lua_space(source, position)

    while position < len(source):
      if source.startswith("..", position):
        position += 2
        position = skip_lua_space(source, position)

        value, position = parse_lua_string(source, position)

        if value is None:
          break

        parts.append(value)
        position = skip_lua_space(source, position)
        continue

      if source[position] == ",":
        results.append("".join(parts))
        break

      if source[position] == ")":
        results.append("".join(parts))
        break

      break

  return results


def collect_sources():
  sources = {}

  for path in SOURCE_FILES:
    source = path.read_text(encoding="utf-8")

    for msgid in extract_s_strings(source):
      if msgid == "":
        continue

      sources.setdefault(msgid, set()).add(path.name)

  return sources


def parse_po(path):
  text = path.read_text(encoding="utf-8")
  lines = text.splitlines()

  entries = []
  current = []
  references = []
  msgid = None
  msgstr = None
  field = None

  def finish():
    nonlocal current, references, msgid, msgstr, field

    if msgid is not None:
      entries.append({
        "msgid": msgid,
        "msgstr": msgstr if msgstr is not None else "",
        "references": set(references),
        "lines": current[:],
      })

    current = []
    references = []
    msgid = None
    msgstr = None
    field = None

  for line in lines:
    if line.startswith("#:"):
      references.extend(line[2:].strip().split())
      current.append(line)
      continue

    if line.startswith("msgid "):
      if msgid is not None:
        finish()

      literal = line[6:].strip()

      try:
        msgid = ast.literal_eval(literal)
      except (SyntaxError, ValueError):
        msgid = ""

      field = "msgid"
      current.append(line)
      continue

    if line.startswith("msgstr "):
      literal = line[7:].strip()

      try:
        msgstr = ast.literal_eval(literal)
      except (SyntaxError, ValueError):
        msgstr = ""

      field = "msgstr"
      current.append(line)
      continue

    if line.startswith('"'):
      try:
        value = ast.literal_eval(line)
      except (SyntaxError, ValueError):
        value = ""

      if field == "msgid":
        msgid += value
      elif field == "msgstr":
        msgstr += value

      current.append(line)
      continue

    if line.strip() == "":
      if msgid is not None:
        finish()
      else:
        current.append(line)

      continue

    current.append(line)

  if msgid is not None:
    finish()

  return entries


def get_header(entries):
  for entry in entries:
    if entry["msgid"] == "":
      return entry

  return None


def build_entry(msgid, msgstr, references):
  output = []

  for filename in sorted(references):
    output.append("#: " + filename)

  output.extend(po_lines("msgid", msgid))
  output.extend(po_lines("msgstr", msgstr))

  return output


def write_pot(sources):
  old_entries = parse_po(POT_FILE) if POT_FILE.exists() else []

  old_order = [
    entry["msgid"]
    for entry in old_entries
    if entry["msgid"] != ""
  ]

  ordered_msgids = []

  for msgid in old_order:
    if msgid in sources and msgid not in ordered_msgids:
      ordered_msgids.append(msgid)

  for msgid in sorted(sources):
    if msgid not in ordered_msgids:
      ordered_msgids.append(msgid)

  header = get_header(old_entries)

  output = []

  if header:
    # Preserve the existing POT header exactly.
    output.extend(header["lines"])
  else:
    output.extend([
      'msgid ""',
      'msgstr ""',
      '"Project-Id-Version: jc_special\\n"',
      '"Content-Type: text/plain; charset=UTF-8\\n"',
      '"Content-Transfer-Encoding: 8bit\\n"',
    ])

  output.append("")

  for msgid in ordered_msgids:
    output.extend(build_entry(msgid, "", sources[msgid]))
    output.append("")

  POT_FILE.write_text(
    "\n".join(output).rstrip() + "\n",
    encoding="utf-8"
  )


def write_po(path, sources):
  entries = parse_po(path)

  existing = {
    entry["msgid"]: entry
    for entry in entries
  }

  output = []

  header = existing.get("")

  if header:
    # Preserve the existing PO header exactly.
    output.extend(header["lines"])
    output.append("")
  else:
    # Only create a minimal header if the PO has no header.
    output.extend([
      'msgid ""',
      'msgstr ""',
      '"Project-Id-Version: jc_special\\n"',
      '"Content-Type: text/plain; charset=UTF-8\\n"',
      '"Content-Transfer-Encoding: 8bit\\n"',
      "",
    ])

  old_order = [
    entry["msgid"]
    for entry in entries
    if entry["msgid"] != ""
  ]

  ordered_msgids = []

  for msgid in old_order:
    if msgid in sources and msgid not in ordered_msgids:
      ordered_msgids.append(msgid)

  for msgid in sorted(sources):
    if msgid not in ordered_msgids:
      ordered_msgids.append(msgid)

  for msgid in ordered_msgids:
    old = existing.get(msgid)

    msgstr = old["msgstr"] if old else ""

    output.extend(
      build_entry(
        msgid,
        msgstr,
        sources[msgid]
      )
    )

    output.append("")

  path.write_text(
    "\n".join(output).rstrip() + "\n",
    encoding="utf-8"
  )


def main():
  sources = collect_sources()

  print("Found {} translatable strings.".format(len(sources)))

  write_pot(sources)
  print("Updated {}".format(POT_FILE.relative_to(ROOT)))

  for path in sorted(LOCALE_DIR.glob("jc_special.*.po")):
    write_po(path, sources)
    print("Updated {}".format(path.relative_to(ROOT)))


if __name__ == "__main__":
  main()