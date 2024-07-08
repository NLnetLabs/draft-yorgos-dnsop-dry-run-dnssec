VERSION = 02
DOCNAME = draft-yorgos-dnsop-dry-run-dnssec
today := $(shell TZ=UTC date +%Y-%m-%dT00:00:00Z)

.PHONY: all prereq clean

all: $(DOCNAME)-$(VERSION).txt $(DOCNAME)-$(VERSION).html

$(DOCNAME)-$(VERSION).txt: $(DOCNAME).xml
	xml2rfc --text -o $@ $<

$(DOCNAME)-$(VERSION).html: $(DOCNAME).xml
	xml2rfc --html -o $@ $<

$(DOCNAME).xml: $(DOCNAME).md prereq
	sed -e 's/@DOCNAME@/$(DOCNAME)-$(VERSION)/g' \
	    -e 's/@TODAY@/${today}/g'  $< | mmark > $@ || rm -f $@

prereq:
	@echo "Checking prerequisites..."
	xml2rfc --version
	mmark -version

clean:
	rm -f $(DOCNAME).xml $(DOCNAME)-$(VERSION).txt $(DOCNAME)-$(VERSION).html
