# Generate my website out of org-mode/gemini files
#
# maybe check https://themattchan.com/blog/2017-02-28-make-site-generator.html
# From https://github.com/fcanas/bake/blob/master/Makefile
# Finally https://www.arsouyes.org/blog/2017/10_Static_website/

all: fast
SRC_DIR ?= src
DST_DIR ?= _site
CACHE_DIR ?= .cache

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
                        $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%, \
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
	$(PANDOC) $< --output $@.tmp
	minify --mime text/html $@.tmp > $@
	@rm $@.tmp
ALL += $(DST_PANDOC_FILES)



# HTML INDEX
HTML_INDEX := $(DST_DIR)/index.html
MKINDEX := engine/mk-index.sh
$(HTML_INDEX): $(DST_PANDOC_FILES) $(MKINDEX)
	@mkdir -p $(DST_DIR)
	$(MKINDEX)
ALL += $(HTML_INDEX)

# RSS
SRC_POSTS_DIR ?= $(SRC_DIR)/posts
DST_POSTS_DIR ?= $(DST_DIR)/posts
SRC_POSTS_FILES ?= $(shell find $(SRC_POSTS_DIR) -type f -name "*$(EXT)")
RSS_CACHE_DIR ?= $(CACHE_DIR)/rss
DST_RSS_FILES ?= $(patsubst %.org,%.rss, \
                        $(patsubst $(SRC_POSTS_DIR)/%,$(RSS_CACHE_DIR)/%, \
                            $(SRC_POSTS_FILES)))
MK_RSS_ENTRY := ./engine/mk-rss-entry.sh
$(RSS_CACHE_DIR)/%.rss: $(DST_POSTS_DIR)/%.html $(MK_RSS_ENTRY)
	@mkdir -p $(RSS_CACHE_DIR)
	$(MK_RSS_ENTRY) "$<" "$@"
ALL += $(DST_RSS_FILES)

RSS := $(DST_DIR)/rss.xml
MKRSS := engine/mkrss.sh
$(RSS): $(DST_RSS_FILES) $(MKRSS)
	$(MKRSS)
ALL += $(RSS)

rss: $(DST_RSS_FILES) $(RSS)


# ORG -> GEMINI
EXT := .org
SRC_GMI_FILES ?= $(shell find $(SRC_DIR) -type f -name "*$(EXT)" $(NO_DRAFT))
DST_GMI_FILES ?= $(subst $(EXT),.gmi, \
                        $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%, \
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

# RSS
GEM_ATOM := $(DST_DIR)/gem-atom.xml
MK_GEMINI_ATOM := engine/mk-gemini-atom.sh
$(GEM_ATOM): $(DST_GMI_FILES) $(MK_GEMINI_ATOM)
	$(MK_GEMINI_ATOM)
ALL += $(GEM_ATOM)

gemini: $(DST_GMI_FILES) $(GMI_INDEX) $(GEM_ATOM)

# Images
SRC_IMG_FILES ?= $(shell find $(SRC_DIR) -type f -name "*.jpg" -or -name "*.jpeg" -or -name "*.gif" -or -name "*.png")
DST_IMG_FILES ?= $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%, $(SRC_IMG_FILES))

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

ALL += $(DST_IMG_FILES)
# DEPLOY

deploy: $(ALL)
	engine/sync.sh # deploy to her.esy.fun
	engine/ye-com-fastpublish.hs # deploy to yannesposito.com (via github pages)

fast: $(ALL)

.PHONY: clean

clean:
	-[ ! -z "$(DST_DIR)" ] && rm -rf $(DST_DIR)/*
	-[ ! -z "$(CACHE_DIR)" ] && rm -rf $(CACHE_DIR)/*
