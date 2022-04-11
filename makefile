files = README.pdf README.docx consort.pdf

.PHONY: all clean

all: $(files)

consort.pdf: consort.dot
	dot -Tpdf -o $@ $<

%.pdf: %.md
	pandoc -o $@ $<

%.docx: %.md
	pandoc -o $@ $<

clean:
	rm -rf $(files)
