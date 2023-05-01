final_title = cancer-dqm-manual
files = consort.pdf consort.png $(final_title).pdf $(final_title).docx $(final_title).md
dir = ../pseudocode

.PHONY: all clean

all: $(files)

## Main pseudocode
## Note, md files all live in outputs/ directory

%.pdf: %.md
	pandoc -o $@ $<

%.docx: %.md
	pandoc -o $@ $<

## Intermediate file (1 markdown out of a concatenation of 3)
# The auto variable $+ does all prereqs in order.

$(final_title).md: $(dir)/manual-main.md $(dir)/manual-appendix-1.md $(dir)/manual-appendix-2.md
	cat $+ > $@

## graphviz

consort.pdf: ../consort.dot
	dot -Tpdf -o $@ $<

%.png: ../%.dot
	dot -Tpng -o $@ $<

## clean

clean:
	rm -rf $(files)
