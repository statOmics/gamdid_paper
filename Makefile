.PHONY: all data simulations caseStudy manuscript figures pdfs gamdid_manuscript.pdf word clean

all: data simulations caseStudy manuscript

## Analysis targets

data:
	R CMD BATCH --no-restore --no-save make_data.R

simulations:
	R CMD BATCH --no-restore --no-save make_simulations.R

caseStudy:
	R CMD BATCH --no-restore --no-save make_caseStudy.R

## Manuscript targets

manuscript:
	$(MAKE) figures
	$(MAKE) pdfs

figures:
	R CMD BATCH --no-restore --no-save manuscript/figs/make_figures.R

## The manuscript (LTJournalArticle class) uses biblatex with the biber backend.
## biber must match the installed biblatex version: the copy in ~/bin is used
## when present, override with e.g. `make gamdid_manuscript.pdf BIBER=biber`.
BIBER ?= $(shell if [ -x "$(HOME)/bin/biber" ]; then echo "$(HOME)/bin/biber"; else echo biber; fi)
LATEX = pdflatex -interaction=nonstopmode -halt-on-error

## `make pdfs` builds four PDFs from manuscript/main.tex, using the existing
## figures (no R is run):
##   gamdid_manuscript.pdf, gamdid_supplemental_figures.pdf,
##   gamdid_supplemental_tables.pdf, gamdid_supplemental_methods.pdf
## main.tex picks the document from \gamdidpart (manuscript, figures, tables,
## methods); -jobname sets the PDF name. The documents reference each other's
## labels (xr-hyper reads the other documents' .aux files), so all four are
## compiled together: one LaTeX pass, biber, then two more passes so
## cross-document numbers settle.
SUPPL = gamdid_supplemental_figures gamdid_supplemental_tables gamdid_supplemental_methods
## Documents with citations, i.e. that need biber
BIBDOCS = gamdid_manuscript gamdid_supplemental_methods

define latex_all
	cd manuscript && $(LATEX) -jobname=gamdid_manuscript main.tex >/dev/null || { tail -40 gamdid_manuscript.log; exit 1; }
	cd manuscript && for p in figures tables methods; do $(LATEX) -jobname=gamdid_supplemental_$$p "\def\gamdidpart{$$p}\input{main}" >/dev/null || { tail -40 gamdid_supplemental_$$p.log; exit 1; }; done
endef

## Cleans before (no stale .aux from earlier builds) and after (no leftovers).
pdfs:
	$(MAKE) clean
	$(latex_all)
	cd manuscript && for d in $(BIBDOCS); do $(BIBER) --quiet $$d || exit 1; done
	$(latex_all)
	$(latex_all)
	@echo "Built: $(addprefix manuscript/,$(addsuffix .pdf,gamdid_manuscript $(SUPPL)))"
	$(MAKE) clean

gamdid_manuscript.pdf: pdfs

## `make word` builds manuscript/gamdid_manuscript.docx: the main manuscript
## only (no supplemental documents), converted with pandoc, using the existing
## figures (no R is run). See manuscript/word/build_word.sh.
word:
	sh manuscript/word/build_word.sh

## Cleaning artefacts

## Only LaTeX artefacts in manuscript/ are removed: the project root
## holds a large .RData workspace that must not be deleted.
clean:
	@find manuscript -type f \( -name "*.aux" -o -name "*.log" -o -name "*-blx.bib" -o -name "*.run.xml" -o -name "*.bcf" -o -name "*.out" -o -name "*.suppinfo" -o -name "*.toc" -o -name "*.lof" -o -name "*.lot" -o -name "*.bbl" -o -name "*.blg" -o -name "*.synctex.gz" -o -name "*.fls" -o -name "*.fdb_latexmk" \) -exec rm -rf {} \;
	@rm -f manuscript/Rplots.pdf Rplots.pdf
