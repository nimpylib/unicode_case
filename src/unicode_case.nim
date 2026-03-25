
import std/unicode except split, isTitle, isUpper
import std/strutils except strip, split, rsplit
import std/tables
from std/algorithm import binarySearch

include ./private/[
  toUpperMapper, casefoldMapper, istitleButNotIsUpper,
]
import ./unicode_case/utils
import pkg/nimpatch/castChar

const
  OneUpperToMoreTable = toTable OneUpperToMoreTableLit


type
  RuneI = int32
  CasefoldInnerTab[K, V] = Table[K, V]
  CasefoldTableT = object
    common: CasefoldInnerTab[RuneI, RuneI]
    full: CasefoldInnerTab[RuneI, string]

const CasefoldTable = CasefoldTableT(
  common: toTable CommonMapper,
  full: toTable FullMapper
)

func add(result: var seq[Rune], ls: string) =
  for r in ls.runes: result.add r

func addCasefold[S: string|seq[Rune]](res: var S, k: Rune) =
  template tab: untyped = CasefoldTable
  template add(s: var S, ri: RuneI) =
    s.add Rune ri
  let runeI = RuneI k
  template addIfIn(table) =
    let val = table.getOrDefault runeI
    if val != default typeof val:
      res.add val
      return
  addIfIn tab.common
  addIfIn tab.full
  res.add k

template loop(init, s, L, doWith_ch) =
  result = init(L)
  for ch{.inject.} in s:
    doWith_ch

template gen_with_body(name; body){.dirty.} =
  template `name Impl`(s; L: int; init: typed) = body
  func name*(s: string): string = `name Impl` s.runes, s.len, newStringOfCap
  func name*(s: openArray[Rune]): seq[Rune] = `name Impl` s, s.len, newSeqOfCap[Rune]
template gen_ch_no_char(name; pre; doWith_ch){.dirty.} =
  gen_with_body name:
    pre
    loop(init, s, L, doWith_ch)

template gen_ch_no_char(name; doWith_ch){.dirty.} =
  gen_ch_no_char(name): discard
  do: doWith_ch

template gen_ch(name; pre; doWith_ch; doWith_char){.dirty.} =
  gen_ch_no_char(name, pre, doWith_ch)
  func name*(s: openArray[char]): seq[char] =
    pre
    loop newSeqOfCap[char], s, s.len, doWith_char

template gen_ch(name; doWith_ch; doWith_char) =
  gen_ch(name): discard
  do: doWith_ch
  do: doWith_char

gen_ch_no_char casefold:
  result.addCasefold ch

gen_ch toLower:
  if ch == Rune(304):
    result.add "i\u0307"
    continue
  result.add unicode.toLower ch
do:
  result.add toLowerAscii ch

gen_ch toUpper:
  let ss = OneUpperToMoreTable.getOrDefault ch.int32
  if ss.len == 0:
    result.add ch.toUpper
  else:
    result.add ss
do:
  result.add toUpperAscii ch

proc isTitleButNotIsUpper(r: Rune): bool{.inline.} =
  ## `isTitle` but not `isUpper`
  ##  e.g. `ǅ` is title but not upper, while `Ǆ` is upper but not title.
  0 <= binarySearch(IsTitleButNotIsUpper, r.int32)

#XXX:NIM-BUG: `isUpper` in Nim is different from that in Python.
template isUpperOrTitle(r: Rune): bool = unicode.isUpper(r)
proc isUpper(r: Rune): bool =
  ## `isUpper` in Python is different from `isUpper` in Nim.
  isUpperOrTitle(r) and not isTitleButNotIsUpper(r)

template genIsX(name){.dirty.} =
  template name(c: char): bool = `name Ascii` c
genIsX islower
genIsX isupper
template isUpperOrTitle(r: char): bool = isUpper(r)


template genCaseOrTitle(prc; isTitle){.dirty.} =
  proc `prc ortitle`(r: Rune): bool = prc(r) or isTitle(r)
  proc `prc ortitle`(r: char): bool = prc(r)

genCaseOrTitle isLower, unicode.isTitle

func isCased(r: Rune): bool =
  ## Unicode standard 5.0 introduce `isCased`
  r.isLower or r.isUpperOrTitle

type RuneImpl = int32
proc py_toTitle(r: Rune): Rune =
  ## unicode.toTitle only respect those whose
  ## titlecase differs uppercase.
  ## e.g.
  ##  not respect ascii
  var c = RuneImpl(r)
  if c <= RuneImpl high char:
    return castChar(c).toUpperAscii.Rune
  result = r.toTitle()
  if result == r:
    # Nim's toTitle only convert those whose titlecase differs uppercase.
    return r.toUpper()
    ## when it comes to Ligatures,
    ##  toUpper() will do what `title()` in Python does
    ##  for example, `'ῃ'.upper()` gives `'HI'` in Python (length becomes 2)
    ##  but Nim's `toUpper`'s result is always of 1 length, and
    ##  `"ῃ".runeAt(0).toUpper` gives `ῌ`, a.k.a. `'ῃ'.title()` in Python.

gen_ch toTitle:
  var previous_is_cased = false
do:
  result.add:
    if previous_is_cased: ch.toLower
    else: ch.py_toTitle
  previous_is_cased = ch.isCased
do:
  var c = ch
  if ch.isLowerAscii:
    if not previous_is_cased:
      c = c.toUpperAscii
    previous_is_cased = true
  elif ch.isUpperAscii:
    if previous_is_cased:
      c = c.toLowerAscii
    previous_is_cased = true
  else:
    previous_is_cased = false
  result.add c

const
  PyMajor{.intdefine.} = 3
  PyMinor{.intdefine.} = 14

func add(result: var string, ls: seq[char]) =
  for c in ls:
    result.add c

template capitalizeImpl(subs; py_toUpper, py_toTitle) =
  let first = when (PyMajor, PyMinor) < (3,8):
    py_toUpper(rune)
  else:
    py_toTitle(rune)
  result.add first
  result.add subs.toLower()

template capitalizeImpl(i) = capitalizeImpl(i, py_toUpper, py_toTitle)

func capitalize*(s: string): string =
  if s.len == 0: return
  var
    rune: Rune
    i = 0
  fastRuneAt(s, i, rune, doInc = true)
  capitalizeImpl s[i..^1]

func capitalize*(s: openArray[char]): seq[char] =
  if s.len == 0: return
  let rune = s[0]
  capitalizeImpl s.toOpenArray(1, s.high), toUpperAscii, toUpperAscii

func capitalize*(s: openArray[Rune]): seq[Rune] =
  if s.len == 0: return
  let rune = s[0]
  capitalizeImpl s.toOpenArray(1, s.high)

template firstChar(s: string): Rune = s.runeAt 0
template strAllAlpha(s: string; isWhat, notWhat): untyped =
  s.allAlpha isWhat, notWhat, runes, firstChar

template asIs(x): untyped = x
template firstChar[C](s: openArray[C]): C = s[0]
template strAllAlpha[C](s: openArray[C]; isWhat, notWhat): untyped =
  s.allAlpha isWhat, notWhat, asIs, firstChar

template genIs3(T; runes){.dirty.} =
  func islower*(a: T): bool = a.strAllAlpha isLower, `isUpper ortitle`
  func isupper*(a: T): bool = a.strAllAlpha isUpper, `isLower ortitle`
  func istitle*(a: T): bool =
    a.istitleImpl `isUpper ortitle`, isLower, runes, firstChar

genIs3 string, runes
genIs3 openArray[char], runes
genIs3 openArray[Rune], asIs


