

template allAlpha*(a, isWhat, isNotWhat; iter, firstItemGetter) =
  ## used as func body.
  ## e.g.
  ## func isupper(self: PyBytes): bool =
  ##   self.allAlpha(isUpperAscii, isLowerAscii, items, `[0]`)
  let le = len(a)
  if le == 1: return isWhat(a.firstItemGetter)
  if le == 0: return false
  var notRes = true
  for r in a.iter:
    if r.isNotWhat:
      return false
    elif notRes and r.isWhat:
      notRes = false
  result = not notRes

template istitleImpl*(a, isupper, islower: typed, iter, firstItemGetter) =
  let le = len(a)
  if le == 1:
    let c = a.firstItemGetter
    if c.isupper: return true
    return false
  if le == 0: return false

  var cased, previous_cased: bool

  for ch in a.iter:
    if ch.isupper:
      if previous_cased:
        return false
      previous_cased = true
      cased = true
    elif ch.islower:
      if not previous_cased:
        return false
      previous_cased = true
      cased = true
    else:
      previous_cased = false
  result = cased

template runeCheck*(runes; byteLen: int; runePredict: typed; zeroLenTrue: static[bool]) =
  ## Common code for isascii and isspace.
  result = when zeroLenTrue: true
  else:
    if byteLen == 0: false else: true
  for r in runes:
    if not runePredict r:
      return false

