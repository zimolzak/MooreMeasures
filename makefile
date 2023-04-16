files = README.pdf README.docx consort.pdf consort.png
files += discovery-manual.pdf discovery-manual.docx

.PHONY: all clean

all: $(files)

consort.pdf: consort.dot
	dot -Tpdf -o $@ $<

%.png: %.dot
	dot -Tpng -o $@ $<

%.pdf: %.md
	pandoc -o $@ $<

%.docx: %.md
	pandoc -o $@ $<

## manual

discovery-manual.md: discovery.md lung-icd10.md colon-icd10.md
	cat discovery.md colon-icd10.md lung-icd10.md > $@

## clean

clean:
	rm -rf $(files)
