TEXFILE = paper
BIBFILE = bib

all: $(TEXFILE).pdf

$(TEXFILE).pdf: $(TEXFILE).tex $(BIBFILE).bib
	pdflatex $(TEXFILE).tex
	bibtex $(TEXFILE)
	pdflatex $(TEXFILE).tex
	pdflatex $(TEXFILE).tex

clean:
	rm -f *.aux *.bbl *.blg *.log *.out *.toc *.lof *.lot *.nav *.snm *.synctex.gz *.fdb_latexmk *.fls *.ins paper.pdf

.PHONY: all clean
