SC-ripts
========

Scripts (mainly related to (La)TeX) for Snowman Comedians

![NICE!](https://raw.githubusercontent.com/zr-tex8r/SC-ripts/images/essence-2.png)  
*The “essential” one*

scmakesvf ― SC-variant of makejvf
----------------------------------

This is an *essential* version of the makejvf program. While makejvf is
handy for creating Japanese VF (JVF), this program is handy for creating
Snowman VF (☃VF).

scmendex ― SC-variant of mendex
--------------------------------

This is an *essential* version of [mendex] (Japanese-aware version of
Makeindex program). While mendex is oriented to the Japanese language,
scmendex is oriented to snowman information, and you can create more
*essential* index.

scptex2pdf ― SC-variant of ptex2pdf
------------------------------------

This is an *essential* version of [ptex2pdf]. You can obtain more fancy
and *essential* PDF output than when using ordinary ptex2pdf.

[ptex2pdf]: https://github.com/texjporg/ptex2pdf

```
Usage: [texlua] scptex2pdf[.lua] { option | basename[.tex] } ...
```

The command format is the same as ptex2pdf.

scxml2ltx ― SC-generic XML→LaTeX Converter
--------------------------------------------

This software converts an arbitrary XML document to LaTeX format. It is
intended to be super-generic: the input document need not be valid against
some schema, or well-formed, or even look like an XML text, The input can
be virtually anything, but the all sematics that is not *essential*
will be ignored, and thus the output is always *essential*.

```
Usage: scxml2ltx[.lua] [-i <in_file>] [-o <out_file>] [-C] [-S|-s <params>]
  -i <in_file>      input file name (default is stdin)
  -o <out_file>     output file name (default is stdout)
  -C                skip check for existence of files
  -S                not use scsnowman
  -s <params>       use scsnowman (with given params)
  -v                verbose
```

--------------------

S(C)ee Also
-----------

  * [sctexdoc]: Another *essential* script by wtsnjp
  * [SC-tools]: *Essential* LaTeX packages

[sctexdoc]: https://gist.github.com/wtsnjp/3bfcdb32420fa591c9fe641dbe932d38
[SC-tools]: https://github.com/zr-tex8r/SC-tools

--------------------
Takayuki YATO (aka. "ZR") 
http://zrbabbler.sp.land.to/
