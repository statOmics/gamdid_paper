#!/bin/sh
## Builds manuscript/gamdid_manuscript.docx (the main manuscript only, no
## supplemental documents) with pandoc. Run via `make word` in gamdid_paper/.
##
## main.tex itself cannot be read by pandoc (custom class, \ifx switches), so
## a plain LaTeX file is assembled from it: title, authors and affiliations
## from the main.tex preamble, the abstract, and the article contents
## (introduction up to the bibliography). Then:
##   - one pdflatex pass per document writes .aux files, from which
##     word/refs.lua takes the figure/table/equation numbers, so references
##     (incl. "Supplemental Figure S3") match the PDFs;
##   - pandoc --citeproc formats citations and references (Vancouver style).
set -e
cd "$(dirname "$0")/.."   # manuscript/

OUT=gamdid_manuscript.docx
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

## 1. Label numbers: one LaTeX pass per document, no PDF written
LATEX="pdflatex -interaction=nonstopmode -halt-on-error -draftmode -output-directory=$TMP"
$LATEX -jobname=gamdid_manuscript main.tex >/dev/null ||
	{ tail -40 "$TMP/gamdid_manuscript.log"; exit 1; }
for p in figures tables methods; do
	$LATEX -jobname=gamdid_supplemental_$p "\def\gamdidpart{$p}\input{main}" >/dev/null ||
		{ tail -40 "$TMP/gamdid_supplemental_$p.log"; exit 1; }
done

## 2. Plain LaTeX version of the manuscript
TEX="$TMP/gamdid_word.tex"
{
	printf '%s\n' '\newcommand{\lc}[1]{#1}' '\newcommand{\lieven}[1]{#1}' '\newcommand{\lucas}[1]{#1}'
	# title, without the manual line break
	sed -n 's/^\\newcommand{\\papertitle}{\(.*\)} *%.*$/\\title{\1}/p' main.tex | sed 's/ *\\\\ */ /g'
	# authors with affiliation numbers as superscripts
	printf '\\author{'
	sed -n 's/^\\author\[\([^]]*\)\]{\([^\\}]*\).*$/\2\\textsuperscript{\1}/p' main.tex |
		sed '$!s/$/ \\and/' | tr '\n' ' '
	printf '}\n\\date{}\n\\begin{document}\n\\maketitle\n\n'
	# affiliations and corresponding author
	sed -n 's/^\\affil\[\([^]]*\)\]{\(.*\)}[[:space:]]*$/\\textsuperscript{\1}\2/p' main.tex | sed G
	sed -n 's/^\\author.*\\thanks{\([^}]*\)}.*$/\1/p' main.tex | sed G
	# abstract as an ordinary unnumbered section, after the affiliations
	sed 's/\\begin{abstract}/\\section*{Abstract}/; s/\\end{abstract}//' sections/abstract.tex
	# article contents (introduction ... acknowledgements)
	sed -n '/^\\input{sections\/introduction}/,/^\\printbibliography/p' main.tex |
		sed '/^\\printbibliography/d; /^\\newpage/d'
	printf '\n\\end{document}\n'
} > "$TEX"

## 3. Figures: pandoc can only read the pixel size of JPEGs with a JFIF/Exif
## header; without it, every figure gets a fixed 4in fallback size and the
## LaTeX widths (e.g. 0.85\linewidth) are lost. The figures start with an
## Adobe marker, so copies get a JFIF header added (lossless: pixels untouched).
mkdir "$TMP/figs"
python3 - "$TMP/figs" figs/*.jpg <<'EOF'
import os, struct, sys
out = sys.argv[1]
# JFIF APP0 segment, 300 dpi
app0 = b'\xff\xe0' + struct.pack('>H', 16) + b'JFIF\x00\x01\x01\x01' + struct.pack('>HH', 300, 300) + b'\x00\x00'
for f in sys.argv[2:]:
    data = open(f, 'rb').read()
    if data[2:4] not in (b'\xff\xe0', b'\xff\xe1'):
        data = data[:2] + app0 + data[2:]
    open(os.path.join(out, os.path.basename(f)), 'wb').write(data)
EOF

## 4. Convert. word/reference.docx sets the page as in the PDF (A4, 2cm side
## margins), so figure widths relative to the line width match the PDF, and
## adds page numbers in the footer.
GAMDID_AUX="$TMP" pandoc "$TEX" -f latex -t docx+native_numbering -o "$OUT" \
	--reference-doc=word/reference.docx \
	--resource-path="$TMP:." \
	--lua-filter=word/refs.lua \
	--citeproc --csl=word/vancouver.csl \
	--bibliography=bibliography/articles.bib \
	--bibliography=bibliography/software.bib \
	-M reference-section-title=References

echo "Built: manuscript/$OUT"
