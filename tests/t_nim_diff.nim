
import std/unittest
from std/unicode import Rune, `$`

import unicode_case
test "diff nim":
  let r = Rune(456)
  assert unicode.isUpper(r)
  check not [r].isupper()
  check unicode.isTitle(r)

