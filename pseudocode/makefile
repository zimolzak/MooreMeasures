files = README.pdf README.docx discovery-manual.pdf discovery-manual.docx

.PHONY: all clean

all: $(files)

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
