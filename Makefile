# Generate my website out of org-mode/gemini files
#
# maybe check https://themattchan.com/blog/2017-02-28-make-site-generator.html
# From https://github.com/fcanas/bake/blob/master/Makefile
# Finally https://www.arsouyes.org/blog/2017/10_Static_website/

all: allatend
SRC_DIR ?= src
DST_DIR ?= _site
SRC_RAW_FILES := $(shell find $(SRC_DIR) -type f)
DST_RAW_FILES   := $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%,$(SRC_RAW_FILES))
ALL             += $(DST_RAW_FILES)

$(DST_DIR)/% : $(SRC_DIR)/%
	mkdir -p "$(dir $@)"
	cp "$<" "$@"


EXT := .org
SRC_PANDOC_FILES ?= $(shell find $(SRC_DIR) -type f -name "*$(EXT)")
DST_PANDOC_FILES ?= $(subst $(EXT),.html, \
                        $(subst $(SRC_DIR),$(DST_DIR), \
                            $(SRC_PANDOC_FILES)))

ALL              += $(DST_PANDOC_FILES)


TEMPLATE ?= templates/post.html
CSS = /css/y.css
PANDOC := pandoc \
			-c $(CSS) \
			--template=$(TEMPLATE) \
			--from org \
			--to html5 \
			--standalone


$(DST_DIR)/%.html: $(SRC_DIR)/%.org $(TEMPLATE)
	mkdir -p $(dir $@)
	$(PANDOC) $< \
		--output $@

allatend: $(ALL)

clean:
	rm -rf $(DST_DIR)/*
