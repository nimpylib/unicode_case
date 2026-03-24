

import sys, pathlib
sys.path.append(pathlib.Path(__file__).parent)

from utils import *

def itor():
  for i in UNICODES_RANGE:
    c = chr(i)
    uc = c.upper()
    le = len(uc)
    if le != 1:
      ucs_b = uc.encode('unicode-escape')
      ucs = ucs_b.decode('ascii')
      yield (f"{i}'i32",  f"\"{ucs}\"")
      #ucs = ""
      #for ucc in uc: ucs += str(ord(ucc)) + ' '
      #print(f'{i:<7}->{ucs:>12}')

def main():
  print("""# only one character that will be extended to more characters when tolower:
#  chr(304) a.k.a. LATIN CAPITAL LETTER I WITH DOT ABOVE""")
  gen_map("OneUpperToMoreTableLit", itor())

gen("toUpperMapper.nim", main)

