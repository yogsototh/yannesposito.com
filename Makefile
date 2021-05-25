# Generate my website out of org-mode/gemini files


all: site
SRC_DIR ?= src
DST_DIR ?= _site
CACHE_DIR ?= .cache

# we don't want to publish files in drafts
NO_DRAFT := -not -path '$(SRC_DIR)/drafts/*'
# we don't copy source files
NO_SRC_FILE := ! -name '*.org'

# ASSETS
SRC_RAW_FILES := $(shell find $(SRC_DIR) -type f $(NO_DRAFT) $(NO_SRC_FILE))
DST_RAW_FILES   := $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%,$(SRC_RAW_FILES))
$(DST_DIR)/%: $(SRC_DIR)/%
	@mkdir -p "$(dir $@)"
	cp "$<" "$@"
.PHONY: assets
assets: $(DST_RAW_FILES)
ALL += assets

# CSS
SRC_CSS_FILES := $(shell find $(SRC_DIR) -type f -name '*.css')
DST_CSS_FILES   := $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%,$(SRC_RAW_FILES))
$(DST_DIR)/%.css: $(SRC_DIR)/%.css
	@mkdir -p "$(dir $@)"
	minify "$<" > "$@"
css: $(DST_CSS_FILES)
ALL += css

# ORG -> HTML
EXT ?= .org
SRC_PANDOC_FILES ?= $(shell find $(SRC_DIR) -type f -name "*$(EXT)" $(NO_DRAFT))
DST_PANDOC_FILES ?= $(patsubst %$(EXT),%.html, \
                        $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%, \
                            $(SRC_PANDOC_FILES)))
PANDOC_TEMPLATE ?= templates/post.html
MK_HTML := engine/mk-html.sh
PANDOC := $(MK_HTML) $(PANDOC_TEMPLATE)
$(DST_DIR)/%.html: $(SRC_DIR)/%.org $(PANDOC_TEMPLATE) $(MK_HTML)
	@mkdir -p "$(dir $@)"
	$(PANDOC) "$<" "$@.tmp"
	minify --mime text/html "$@.tmp" > "$@"
	@rm "$@.tmp"
.PHONY: html
html: $(DST_PANDOC_FILES)
ALL += html

# INDEXES
SRC_POSTS_DIR ?= $(SRC_DIR)/posts
DST_POSTS_DIR ?= $(DST_DIR)/posts
SRC_POSTS_FILES ?= $(shell find $(SRC_POSTS_DIR) -type f -name "*$(EXT)")
RSS_CACHE_DIR ?= $(CACHE_DIR)/rss
DST_XML_FILES ?= $(patsubst %.org,%.xml, \
                        $(patsubst $(SRC_POSTS_DIR)/%,$(RSS_CACHE_DIR)/%, \
                            $(SRC_POSTS_FILES)))
$(RSS_CACHE_DIR)/%.xml: $(DST_POSTS_DIR)/%.html
	@mkdir -p "$(dir $@)"
	hxclean "$<" > "$@"
.PHONY: indexcache
indexcache: $(DST_XML_FILES)
ALL += indexcache

# HTML INDEX
DST_INDEX_FILES ?= $(patsubst %.xml,%.index, $(DST_XML_FILES))
MK_INDEX_ENTRY := ./engine/mk-index-entry.sh
INDEX_CACHE_DIR ?= $(CACHE_DIR)/rss
$(INDEX_CACHE_DIR)/%.index: $(INDEX_CACHE_DIR)/%.xml $(MK_INDEX_ENTRY)
	@mkdir -p $(INDEX_CACHE_DIR)
	$(MK_INDEX_ENTRY) "$<" "$@"

HTML_INDEX := $(DST_DIR)/index.html
MKINDEX := engine/mk-index.sh
INDEX_TEMPLATE ?= templates/index.html
$(HTML_INDEX): $(DST_INDEX_FILES) $(MKINDEX) $(INDEX_TEMPLATE)
	@mkdir -p $(DST_DIR)
	$(MKINDEX)
.PHONY: index
index: $(HTML_INDEX)
ALL += index

# RSS
DST_RSS_FILES ?= $(patsubst %.xml,%.rss, $(DST_XML_FILES))
MK_RSS_ENTRY := ./engine/mk-rss-entry.sh
$(RSS_CACHE_DIR)/%.rss: $(RSS_CACHE_DIR)/%.xml $(MK_RSS_ENTRY)
	@mkdir -p $(RSS_CACHE_DIR)
	$(MK_RSS_ENTRY) "$<" "$@"

RSS := $(DST_DIR)/rss.xml
MKRSS := engine/mkrss.sh
$(RSS): $(DST_RSS_FILES) $(MKRSS)
	$(MKRSS)

.PHONY: rss
rss: $(RSS)
ALL += rss


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
.PHONY: gmi
gmi: $(DST_GMI_FILES)

# GEMINI INDEX
GMI_INDEX := $(DST_DIR)/index.gmi
MK_GMI_INDEX := engine/mk-gemini-index.sh
$(GMI_INDEX): $(DST_GMI_FILES) $(MK_GMI_INDEX)
	@mkdir -p $(DST_DIR)
	$(MK_GMI_INDEX)
ALL += $(GMI_INDEX)
.PHONY: gmi-index
gmi-index: $(GMI_INDEX)

# RSS
GEM_ATOM := $(DST_DIR)/gem-atom.xml
MK_GEMINI_ATOM := engine/mk-gemini-atom.sh
$(GEM_ATOM): $(DST_GMI_FILES) $(MK_GEMINI_ATOM)
	$(MK_GEMINI_ATOM)
ALL += $(GEM_ATOM)
.PHONY: gmi-atom
gmi-atom: $(GMI_ATOM)

.PHONY: gemini
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

.PHONY: img
img: $(DST_IMG_FILES)
ALL += $(DST_IMG_FILES)

# DEPLOY
.PHONY: site
site: $(ALL)

.PHONY: deploy
deploy: $(ALL)
	engine/sync.sh # deploy to her.esy.fun
	engine/ye-com-fastpublish.hs # deploy to yannesposito.com (via github pages)

.PHONY: clean
clean:
	-[ ! -z "$(DST_DIR)" ] && rm -rf $(DST_DIR)/*
	-[ ! -z "$(CACHE_DIR)" ] && rm -rf $(CACHE_DIR)/*
