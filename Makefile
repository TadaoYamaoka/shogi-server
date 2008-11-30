
.PHONY: doc
doc: clean
	rdoc --main README -o doc \
	  . shogi-server README mk_html mk_rate

.PHONY: clean
clean:
	-rm -rf doc
