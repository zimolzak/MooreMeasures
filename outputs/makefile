files = consort.pdf consort.png
files += README.pdf README.docx discovery-manual.pdf discovery-manual.docx
dir = ../pseudocode

.PHONY: all clean

all: $(files)

## Main pseudocode

%.pdf: $(dir)/%.md
	pandoc -o $@ $<

%.docx: $(dir)/%.md
	pandoc -o $@ $<

## manual of pseudocode (concatenation of 3)

discovery-manual.md: $(dir)/discovery.md $(dir)/lung-icd10.md $(dir)/colon-icd10.md
	cat $+ > $@  # The auto variable $+ does all prereqs in order.

## graphviz

consort.pdf: ../consort.dot
	dot -Tpdf -o $@ $<

%.png: ../%.dot
	dot -Tpng -o $@ $<

## clean

clean:
	rm -rf $(files)
