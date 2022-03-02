#!/usr/bin/python
""" A simple implementation jq:
"""
import sys
import json
from json import decoder
import traceback

def parse_arg(argv):
  global is_raw, path

  is_raw = "-r" in argv
  if is_raw: argv.remove("-r")
  path = argv[0] if argv else "."

parse_arg(sys.argv[1:])

def get_field(obj, field):
  if not field:
    yield obj
    return
  sub_index = None
  if "[" in field:
    field, o = field.split("[")
    o = o.strip("]")
    if not o:
      for s in obj.get(field, [None]):
        yield s
      return
    sub_index = int(o)
  v = obj.get(field, None)
  if sub_index is not None:
    yield v[sub_index]
  else:
    yield v

def _get(obj, paths):
  if not paths:
    yield obj
    return

  field, paths = paths[0], paths[1:]
  field = field.strip()
  for obj in get_field(obj, field):
    for o in _get(obj, paths):
      yield o
  return

def get(obj, path):
  path = path.strip()
  if path.startswith('"') or path.startswith("'"):
    yield path[1:-1]
    return
  if path.startswith('.'):
    for v in _get(obj, path[1:].split('.')):
      yield v
    return

  if path.startswith('select'):
    # select( .key = "value" )
    sel = path.split('select', 1)[-1].strip()[1:-1]  # strip '()'
    left, right = sel.split('==')
    l = list(get(obj, left))
    r = list(get(obj, right))
    if l == r:
      yield obj

class MyDecoder(decoder.JSONDecoder):
  def decode(self, s, _w=decoder.WHITESPACE.match):
    while s:
      obj, end = self.raw_decode(s, idx=_w(s, 0).end())
      end = _w(s, end).end()
      yield obj
      s = s[end:]

infile = sys.stdin
outfile = sys.stdout
#infile = open('/tmp/1')

with infile:
  try:
    for oo in json.load(infile, cls=MyDecoder):
      for obj in get(oo, path):
        if is_raw and isinstance(obj, str):
          outfile.write(obj)
        else:
          json.dump(obj, outfile, sort_keys=True, indent=4, separators=(",", ": "))
        outfile.write("\n")
  except Exception as e:
    raise SystemExit("Exception: %r" % traceback.format_exc(e))
