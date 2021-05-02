# Generate my website out of org-mode/gemini files
#
# maybe check https://themattchan.com/blog/2017-02-28-make-site-generator.html
# From https://github.com/fcanas/bake/blob/master/Makefile
# Finally https://www.arsouyes.org/blog/2017/10_Static_website/

all: allatend
SRC_DIR ?= src
DST_DIR ?= _site
NO_DRAFT := -not -path '$(SRC_DIR)/drafts/*'
SRC_RAW_FILES := $(shell find $(SRC_DIR) -type f $(NO_DRAFT))
DST_RAW_FILES   := $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%,$(SRC_RAW_FILES))
ALL             += $(DST_RAW_FILES)

# COPY EVERYTHING
$(DST_DIR)/% : $(SRC_DIR)/%
	mkdir -p "$(dir $@)"
	cp "$<" "$@"


# ORG -> HTML
EXT := .org
SRC_PANDOC_FILES ?= $(shell find $(SRC_DIR) -type f -name "*$(EXT)" $(NO_DRAFT))
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


# HTML INDEX
HTML_INDEX := $(DST_DIR)/index.html
MKINDEX := engine/mk-index.sh

$(HTML_INDEX): $(DST_PANDOC_FILES) $(MKINDEX)
	mkdir -p $(DST_DIR)
	$(MKINDEX)

ALL += $(HTML_INDEX)

# ORG -> GEMINI
EXT := .org
SRC_GMI_FILES ?= $(shell find $(SRC_DIR) -type f -name "*$(EXT)" $(NO_DRAFT))
DST_GMI_FILES ?= $(subst $(EXT),.gmi, \
                        $(subst $(SRC_DIR),$(DST_DIR), \
                            $(SRC_GMI_FILES)))

ALL              += $(DST_GMI_FILES)
GMI := engine/org2gemini.sh

$(DST_DIR)/%.gmi: $(SRC_DIR)/%.org $(GMI) engine/org2gemini_step1.sh
	mkdir -p $(dir $@)
	$(GMI) "$<" "$@"


# OPTIM PHASE

OPTIM_DIR ?= _optim
ENGINE_DIR ?= engine
ENGINE_SCRIPTS := $(shell find $(ENGINE_DIR) -type f)
OPTIM := engine/pre-deploy.sh
$(OPTIM_DIR)/index.html:$(DST_RAW_FILES) $(DST_GMI_FILES) $(DST_PANDOC_FILES) $(HTML_INDEX) $(ENGINE_SCRIPTS) $(OPTIM)
	mkdir -p $(OPTIM_DIR)
	$(OPTIM)

optim: $(OPTIM_DIR)/index.html


# DEPLOY

deploy: $(OPTIM_DIR)/index.html
	engine/sync.sh # deploy to her.esy.fun
	engine/ye-com-fastpublish.hs # deploy to yannesposito.com (via github pages)

allatend: $(ALL)

.PHONY: clean

clean:
	-rm -rf $(DST_DIR)/*
	-rm -rf $(OPTIM_DIR)/*
