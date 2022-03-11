files = out.pdf out.docx

.PHONY: all clean

all: $(files)

%.pdf: %.md
	pandoc -o $@ $<

%.docx: %.md
	pandoc -o $@ $<

clean:
	rm -rf $(files)
