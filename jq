#!/bin/bash
# simple python implementation for jq
function pjq() {
  python -c '
import sys
import json
path = sys.argv[1] if sys.argv[1:] else "."
def get_field(obj, field):
  sub_index = None
  if "[" in field:
    field, o = field.split("[")
    sub_index = int(o.strip("]"))

  v = getattr(obj, field, None)
  if not v: return v
  if sub_index is not None:
    return v[sub_index]
  return v
infile = sys.stdin
outfile = sys.stdout

with infile:
  try: obj = json.load(infile)
  except Exception as e: raise SystemExit(e)
for field in path.split("."):
  field = field.strip()
  if field:
    obj = get_field(obj, field)

with outfile:
  json.dump(obj, outfile, sort_keys=True, indent=4, separators=(",", ": "))
  outfile.write("\n")

' "$@"

}

check_command () {
  type jq >/dev/null 2>&1|| {
    alias jq=pjq
  }
}
check_command
exec jq "$@"
