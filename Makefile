
.PHONY: doc
doc: clean
	rdoc --main README -o doc \
	  . shogi-server README mk_html mk_rate csa-file-filter

.PHONY: clean
clean:
	-rm -rf doc
