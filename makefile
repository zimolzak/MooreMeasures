files = consort.pdf consort.png

.PHONY: all clean

all: $(files)
	$(MAKE) -C outputs

consort.pdf: consort.dot
	dot -Tpdf -o $@ $<

%.png: %.dot
	dot -Tpng -o $@ $<

clean:
	rm -rf $(files)
	$(MAKE) -C outputs clean
