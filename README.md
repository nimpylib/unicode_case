
# unicode_case

[![Test](https://github.com/nimpylib/unicode_case/actions/workflows/ci.yml/badge.svg)](https://github.com/nimpylib/unicode_case/actions/workflows/ci.yml)
[![Docs](https://github.com/nimpylib/unicode_case/actions/workflows/docs.yml/badge.svg)](https://github.com/nimpylib/unicode_case/actions/workflows/docs.yml)
<!--[![Commits](https://img.shields.io/github/last-commit/nimpylib/unicode_case?style=flat)](https://github.com/nimpylib/unicode_case/commits/)-->

---

[Docs](https://nimpylib.github.io/unicode_case/)

routines of unicode case like casefold

and note if you find existing routines like isUpper of `std/unicode` in this library,

it means those in `std/unicode` have different meanings from those in Python,
as well as those in this library.

For example, Nim's `isUpper` considers title-case as upper too, while Python's doesn't
