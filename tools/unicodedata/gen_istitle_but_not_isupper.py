


import sys, pathlib
sys.path.append(pathlib.Path(__file__).parent)

from utils import *


def itor():
  suf = "'i32"
  for i in UNICODES_RANGE:
    c = chr(i)
    if c.istitle():
        if c.isupper(): continue
        if c.islower(): assert False, f"{i} {c}"
        yield f"{i}{suf}"
        suf = ""
        # Only the first one needs the suffix, the rest can be without suffix
        #  because they are all in the same array and Nim can infer the type

gen("istitleButNotIsUpper.nim", lambda: gen_array("IsTitleButNotIsUpper", itor()))
