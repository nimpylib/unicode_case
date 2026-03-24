
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

func addCasefold(res: var string, k: Rune) =
  template tab: untyped = CasefoldTable
  template add(s: var string, ri: RuneI) =
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

template gen_with_body(name; body){.dirty.} =
  template `name Impl`(runes) = body
  func name*(s: openArray[char]): string = `name Impl` s.runes
  func name*(s: openArray[Rune]): string = `name Impl` s
template gen_ch(name; pre; doWith_ch){.dirty.} =
  gen_with_body name:
    pre
    result = newStringOfCap s.len
    for ch{.inject.} in runes:
      doWith_ch

template gen_ch(name; doWith_ch) =
  gen_ch(name): discard
  do: doWith_ch

gen_ch casefold:
  result.addCasefold ch

gen_ch toLower:
  if ch == Rune(304):
    result.add "i\u0307"
    continue
  result.add unicode.toLower ch

gen_ch toUpper:
  let s = OneUpperToMoreTable.getOrDefault ch.int32
  if s.len == 0:
    result.add ch.toUpper
  else:
    result.add s

proc isTitleButNotIsUpper(r: Rune): bool{.inline.} =
  ## `isTitle` but not `isUpper`
  ##  e.g. `ǅ` is title but not upper, while `Ǆ` is upper but not title.
  0 <= binarySearch(IsTitleButNotIsUpper, r.int32)

#XXX:NIM-BUG: `isUpper` in Nim is different from that in Python.
template isUpperOrTitle(r: Rune): bool = unicode.isUpper(r)
proc isUpper(r: Rune): bool =
  ## `isUpper` in Python is different from `isUpper` in Nim.
  isUpperOrTitle(r) and not isTitleButNotIsUpper(r)

template genCaseOrTitle(prc; isTitle){.dirty.} =
  proc `prc ortitle`(r: Rune): bool = prc(r) or isTitle(r)

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

const
  PyMajor{.intdefine.} = 3
  PyMinor{.intdefine.} = 14

template capitalizeImpl(i) =
  let first = when (PyMajor, PyMinor) < (3,8):
    py_toUpper(rune)
  else:
    py_toTitle(rune)
  result = $first & s.toOpenArray(i, s.high).toLower()

func capitalize*(s: openArray[char]): string =
  if len(s) == 0: return
  var
    rune: Rune
    i = 0
  fastRuneAt(s, i, rune, doInc = true)
  capitalizeImpl i

func capitalize*(s: openArray[Rune]): string =
  if len(s) == 0: return
  let rune = s[0]
  capitalizeImpl 1

template firstChar(s: openArray[char]): Rune = s.runeAt 0
template strAllAlpha(s: openArray[char]; isWhat, notWhat): untyped =
  s.allAlpha isWhat, notWhat, runes, firstChar

template asIs(x): untyped = x
template firstChar(s: openArray[Rune]): Rune = s[0]
template strAllAlpha(s: openArray[Rune]; isWhat, notWhat): untyped =
  s.allAlpha isWhat, notWhat, asIs, firstChar


template genIs3(T; runes){.dirty.} =
  func islower*(a: T): bool = a.strAllAlpha isLower, `isUpper ortitle`
  func isupper*(a: T): bool = a.strAllAlpha isUpper, `isLower ortitle`
  func istitle*(a: T): bool =
    template isTitle(r: Rune): bool = isTitleButNotIsUpper(r)
    a.istitleImpl `isUpper ortitle`, isLower, runes, firstChar

genIs3 openArray[char], runes
genIs3 openArray[Rune], asIs


