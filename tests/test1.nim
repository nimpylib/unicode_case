
import std/unittest

import unicode_case
test "test":

  check "Hi U".istitle()

  check "HELLO WORLD".isupper()
  check not "c A".isupper()
  check "hello ".islower()

  block:
    let u = "ǉ" # \u01c9
    check u.toTitle() == "ǈ"  # \u01c8
  
  check ("ῃ").toTitle() == "ῌ" # \u1fcc
  check ("aNd What").toTitle() == "And What"

  check capitalize("aBΔ") == "Abδ"
  check "HELLO WORLD".casefold() == "hello world"

