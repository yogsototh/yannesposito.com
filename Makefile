# Generate my website out of org-mode/gemini files
#
# maybe check https://themattchan.com/blog/2017-02-28-make-site-generator.html
# From https://github.com/fcanas/bake/blob/master/Makefile
# Finally https://www.arsouyes.org/blog/2017/10_Static_website/

all: fast
SRC_DIR ?= src
DST_DIR ?= _site

# we don't want to publish files in drafts
NO_DRAFT := -not -path '$(SRC_DIR)/drafts/*'
# we don't copy source files, nor images, they are transformed
NO_SRC_FILE := ! -name '*.org' ! -name '*.jpg' ! -name '*.png' ! -name '*.jpeg' ! -name '*.gif'


# ASSETS
SRC_RAW_FILES := $(shell find $(SRC_DIR) -type f $(NO_DRAFT) $(NO_SRC_FILE))
DST_RAW_FILES   := $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%,$(SRC_RAW_FILES))
$(DST_DIR)/% : $(SRC_DIR)/%
	@mkdir -p "$(dir $@)"
	cp "$<" "$@"
ALL += $(DST_RAW_FILES)


# ORG -> HTML
EXT := .org
SRC_PANDOC_FILES ?= $(shell find $(SRC_DIR) -type f -name "*$(EXT)" $(NO_DRAFT))
DST_PANDOC_FILES ?= $(subst $(EXT),.html, \
                        $(subst $(SRC_DIR),$(DST_DIR), \
                            $(SRC_PANDOC_FILES)))
TEMPLATE ?= templates/post.html
CSS = /css/y.css
PANDOC := pandoc \
			-c $(CSS) \
			--template=$(TEMPLATE) \
			--from org \
			--to html5 \
			--standalone
$(DST_DIR)/%.html: $(SRC_DIR)/%.org $(TEMPLATE)
	@mkdir -p $(dir $@)
	$(PANDOC) $< \
		--output $@
ALL += $(DST_PANDOC_FILES)

# HTML INDEX
HTML_INDEX := $(DST_DIR)/index.html
MKINDEX := engine/mk-index.sh
$(HTML_INDEX): $(DST_PANDOC_FILES) $(MKINDEX)
	@mkdir -p $(DST_DIR)
	$(MKINDEX)
ALL += $(HTML_INDEX)

# ORG -> GEMINI
EXT := .org
SRC_GMI_FILES ?= $(shell find $(SRC_DIR) -type f -name "*$(EXT)" $(NO_DRAFT))
DST_GMI_FILES ?= $(subst $(EXT),.gmi, \
                        $(subst $(SRC_DIR),$(DST_DIR), \
                            $(SRC_GMI_FILES)))
GMI := engine/org2gemini.sh
$(DST_DIR)/%.gmi: $(SRC_DIR)/%.org $(GMI) engine/org2gemini_step1.sh
	@mkdir -p $(dir $@)
	$(GMI) "$<" "$@"
ALL += $(DST_GMI_FILES)

# GEMINI INDEX
GMI_INDEX := $(DST_DIR)/index.gmi
MK_GMI_INDEX := engine/mk-gemini-index.sh
$(GMI_INDEX): $(DST_GMI_FILES) $(MK_GMI_INDEX)
	@mkdir -p $(DST_DIR)
	$(MK_GMI_INDEX)
ALL += $(GMI_INDEX)



# Images
SRC_IMG_FILES ?= $(shell find $(SRC_DIR) -type f -name "*.jpg" -or -name "*.jpeg" -or -name "*.gif" -or -name "*.png")
DST_IMG_FILES ?= $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%, $(SRC_IMG_FILES))

ALL += $(DST_IMG_FILES)

$(DST_DIR)/%.jpg: $(SRC_DIR)/%.jpg
	@mkdir -p $(dir $@)
	convert "$<" -quality 50 -resize 800x800\> "$@"

$(DST_DIR)/%.jpg: $(SRC_DIR)/%.jpeg
	@mkdir -p $(dir $@)
	convert "$<" -quality 50 -resize 800x800\> "$@"

$(DST_DIR)/%.gif: $(SRC_DIR)/%.gif
	@mkdir -p $(dir $@)
	convert "$<" -quality 50 -resize 800x800\> "$@"

$(DST_DIR)/%.png: $(SRC_DIR)/%.png
	@mkdir -p $(dir $@)
	convert "$<" -quality 50 -resize 800x800\> "$@"

# OPTIM PHASE

OPTIM_DIR ?= _optim
ENGINE_DIR ?= engine
ENGINE_SCRIPTS := $(shell find $(ENGINE_DIR) -type f)
OPTIM := engine/pre-deploy.sh
$(OPTIM_DIR)/index.html:$(DST_RAW_FILES) $(DST_GMI_FILES) $(DST_PANDOC_FILES) $(HTML_INDEX) $(ENGINE_SCRIPTS) $(OPTIM)
	@mkdir -p $(OPTIM_DIR)
	$(OPTIM)

optim: $(OPTIM_DIR)/index.html


# DEPLOY

deploy: $(OPTIM_DIR)/index.html
	engine/sync.sh # deploy to her.esy.fun
	engine/ye-com-fastpublish.hs # deploy to yannesposito.com (via github pages)

fast: $(ALL)

.PHONY: clean

clean:
	-rm -rf $(DST_DIR)/*
	-rm -rf $(OPTIM_DIR)/*
