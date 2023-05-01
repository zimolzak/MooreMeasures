files = README.pdf README.docx discovery-manual.pdf discovery-manual.docx
dir = ../pseudocode

.PHONY: all clean

all: $(files)

%.pdf: $(dir)/%.md
	pandoc -o $@ $<

%.docx: $(dir)/%.md
	pandoc -o $@ $<

## manual

discovery-manual.md: $(dir)/discovery.md $(dir)/lung-icd10.md $(dir)/colon-icd10.md
	cat $(dir)/discovery.md $(dir)/colon-icd10.md $(dir)/lung-icd10.md > $@

## clean

clean:
	rm -rf $(files)
