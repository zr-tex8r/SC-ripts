SC-ripts
========

ゆきだるま芸人用の（主に(La)TeX関係の）スクリプト

![NICE!](https://raw.githubusercontent.com/zr-tex8r/SC-ripts/images/essence-2.png)  
“本質的”なナニカ

scmakesvf ― SC版makejvf
------------------------

makejvfユーティリティの“本質的”なバージョンである。makejvfが和文VF（JVF）
の作成に適しているのに対し、scmakejvfはゆきだるまVF（☃VF）の作製に適して
いる。

scmendex ― SC版mendex
----------------------

mendexユーティリティ（和文版のMakeindex）の“本質的”なバージョンである。
mendexは日本語処理に向いているのに対し、scmendexはゆきだるま情報処理に
向いていて、より“本質的”な索引の生成が可能である。

scptex2pdf ― SC版ptex2pdf
--------------------------

[ptex2pdf]ユーティリティの“本質的”なバージョンである。scptex2pdfを使う
ことにより、従来のptex2pdfの場合に比べてより“本質的”なPDF出力を得ること
ができる。

[ptex2pdf]: https://github.com/texjporg/ptex2pdf

```
Usage: [texlua] scptex2pdf[.lua] { option | basename[.tex] } ...
```

コマンド書式はptex2pdfと全く同じである。

scxml2ltx ― SC汎用的 XML→LaTeX コンバータ
-------------------------------------------

本ソフトウェアは任意のXML文書をLaTeX形式に変換する。scxml2ltxは超汎用的に
なることを目指している。すなわち入力文書は、何らかのスキーマに対して妥当で
ある必要も、整形式である必要も、またXMLっぽい見かけである必要すらない。
つまり入力ファイルは何でも構わない。しかし“本質的”でない意味内容は全て
無視されるため、出力は常に“本質的”になることに注意されたい。

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

  * [sctexdoc]： “本質的”なTexdoc（wtsnjp氏作）
  * [scllmk]： “本質的”なllmk
  * [scSATySFi]: “本質的”なSATySFi
  * [SC-tools]： “本質的”なLaTeXパッケージ

[sctexdoc]: https://gist.github.com/wtsnjp/3bfcdb32420fa591c9fe641dbe932d38
[scllmk]: https://github.com/zr-tex8r/scllmk
[scSATySFi]: https://github.com/zr-tex8r/scsatysfi
[SC-tools]: https://github.com/zr-tex8r/SC-tools

--------------------
Takayuki YATO (aka. "ZR") 
http://zrbabbler.sp.land.to/
