
.PHONY: doc
doc: clean
	rdoc --main README -o doc \
	  . shogi-server README mk_html mk_rate csa-file-filter

.PHONY:test-run
test-run: 
	./shogi-server hoge 4000 --floodgate-games floodgate-900-0,floodgate-3600-0

.PHONY: clean
clean:
	-rm -rf doc
