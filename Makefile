# Generate my website out of org-mode/gemini files

all: site
SRC_DIR ?= src
DST_DIR ?= _site
CACHE_DIR ?= .cache

# we don't want to publish files in drafts
NO_DRAFT := -not -path '$(SRC_DIR)/drafts/*'
# we don't copy source files
NO_SRC_FILE := ! -name '*.org' ! -name '*.css'


define adv_rule
  SRC_$(1) := $$(shell find $$(SRC_DIR) -type f $(2))
  DST_$(1) := $$(patsubst $$(SRC_DIR)/%,$$(DST_DIR)/%,$$(SRC_$(1)))
  $$(DST_DIR)/%$(4): $$(SRC_DIR)/%$(4) $$(ENV_VARS)
	@mkdir -p "$$(dir $$@)"
	$(3)
  .PHONY: $(1)
  $(1): $$(DST_$(1))
  ALL += $(1)
endef

define rule
  SRC_$(1) := $$(shell find $$(SRC_DIR) -type f $(2))
  DST_$(1) := $$(patsubst $$(SRC_DIR)/%,$$(DST_DIR)/%,$$(SRC_$(1)))
  $$(DST_DIR)/%.$(1): $$(SRC_DIR)/%.$(1) $$(ENV_VARS)
	@mkdir -p "$$(dir $$@)"
	$(3)
  .PHONY: $(1)
  $(1): $$(DST_$(1))
  ALL += $(1)
endef

# Prevent path/nix bugs
ENV_VARS := ./engine/envvars.sh
NIX_FILES := ./shell.nix  $(shell find nix -type f)
$(ENV_VARS): $(NIX_FILES)
	$(info  Build ${ENV_VARS})
	@echo "export PATH=\"${PATH}\"" >> ./engine/envvars.sh
.PHONY: envvars
envvars: $(ENV_VARS)
ALL += envvars

# ASSETS
$(eval $(call adv_rule,assets,$$(NO_DRAFT) $$(NO_SRC_FILE),cp "$$<" "$$@",))

# CSS
# $(info $(call rule,css,-name '*.css',minify "$$<" > "$$@"))
$(eval $(call rule,css,-name '*.css',minify "$$<" > "$$@"))

# ORG -> HTML
EXT ?= .org
SRC_PANDOC_FILES ?= $(shell find $(SRC_DIR) -type f -name "*$(EXT)" $(NO_DRAFT))
DST_PANDOC_FILES ?= $(patsubst %$(EXT),%.html, \
                        $(patsubst $(SRC_DIR)/%,$(DST_DIR)/%, \
                            $(SRC_PANDOC_FILES)))
PANDOC_TEMPLATE ?= templates/post.html
PANDOC_LUA_FILTER ?= engine/links-to-html.lua
PANDOC_LUA_FILTER_IMG ?= engine/img-to-webp.lua
PANDOC_LUA_METAS ?= engine/metas.lua
MK_HTML := engine/mk-html.sh
PANDOC := $(MK_HTML) $(PANDOC_TEMPLATE) $(PANDOC_LUA_FILTER) $(PANDOC_LUA_FILTER_IMG) $(PANDOC_LUA_METAS)
$(DST_DIR)/%.html: $(SRC_DIR)/%.org $(PANDOC_TEMPLATE) $(PANDOC_LUA_FILTER) $(PANDOC_LUA_FILTER_IMG) $(PANDOC_LUA_METAS) $(MK_HTML) $(ENV_VARS)
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
$(RSS_CACHE_DIR)/%.xml: $(DST_POSTS_DIR)/%.html $(ENV_VARS)
	@mkdir -p "$(dir $@)"
	hxclean "$<" > "$@"
.PHONY: indexcache
indexcache: $(DST_XML_FILES)
ALL += indexcache

# HTML INDEX
DST_INDEX_FILES ?= $(patsubst %.xml,%.index, $(DST_XML_FILES))
MK_INDEX_ENTRY := ./engine/mk-index-entry.sh
INDEX_CACHE_DIR ?= $(CACHE_DIR)/rss
$(INDEX_CACHE_DIR)/%.index: $(INDEX_CACHE_DIR)/%.xml $(MK_INDEX_ENTRY) $(ENV_VARS)
	@mkdir -p $(INDEX_CACHE_DIR)
	$(MK_INDEX_ENTRY) "$<" "$@"

HTML_INDEX := $(DST_DIR)/index.html
MKINDEX := engine/mk-index.sh
INDEX_TEMPLATE ?= templates/index.html
$(HTML_INDEX): $(DST_INDEX_FILES) $(MKINDEX) $(INDEX_TEMPLATE) $(ENV_VARS)
	@mkdir -p $(DST_DIR)
	$(MKINDEX)
.PHONY: index
index: $(HTML_INDEX)
ALL += index

# RSS
DST_RSS_FILES ?= $(patsubst %.xml,%.rss, $(DST_XML_FILES)) $(ENV_VARS)
MK_RSS_ENTRY := ./engine/mk-rss-entry.sh
$(RSS_CACHE_DIR)/%.rss: $(RSS_CACHE_DIR)/%.xml $(MK_RSS_ENTRY)
	@mkdir -p $(RSS_CACHE_DIR)
	$(MK_RSS_ENTRY) "$<" "$@"

RSS := $(DST_DIR)/rss.xml
MKRSS := engine/mkrss.sh
$(RSS): $(DST_RSS_FILES) $(MKRSS) $(ENV_VARS)
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
$(GMI_INDEX): $(DST_GMI_FILES) $(MK_GMI_INDEX) $(ENV_VARS)
	@mkdir -p $(DST_DIR)
	$(MK_GMI_INDEX)
ALL += $(GMI_INDEX)
.PHONY: gmi-index
gmi-index: $(GMI_INDEX)

# RSS
GMI_ATOM := $(DST_DIR)/gem-atom.xml
MK_GEMINI_ATOM := engine/mk-gemini-atom.sh
$(GEM_ATOM): $(DST_GMI_FILES) $(MK_GEMINI_ATOM)
	$(MK_GEMINI_ATOM)
ALL += $(GMI_ATOM)
.PHONY: gmi-atom
gmi-atom: $(GMI_ATOM)

.PHONY: gemini
gemini: $(DST_GMI_FILES) $(GMI_INDEX) $(GEM_ATOM)

# Images
OPTIM_IMG := engine/optim-img.sh

define img
  SRC_IMG_$(1) ?= $$(shell find $$(SRC_DIR) -type f -name "*.$(1)")
  DST_IMG_$(1) ?= $$(patsubst $$(SRC_DIR)/%,$$(DST_DIR)/%,$$(SRC_IMG_$(1)))
  $$(DST_DIR)/%.$(1): $$(SRC_DIR)/%.$(1) $$(OPTIM_IMG)
	@mkdir -p $$(dir $$@)
	$$(OPTIM_IMG) "$$<" "$$@"
  .PHONY: $(1)
  $(1): $$(DST_IMG_$(1))
  ALL += $(1)
endef

$(info $(call img,jpg))
$(eval $(call img,jpg))
$(eval $(call img,jpeg))
$(eval $(call img,gif))
$(eval $(call img,png))

.PHONY: img
img: jpg jpeg gif png

# DEPLOY
.PHONY: site
site: $(ALL)

.PHONY: deploy
deploy: $(ALL)
	engine/sync.sh # deploy to her.esy.fun
	engine/ye-com-fastpublish.hs # deploy to yannesposito.com (via github pages)

.PHONY: clean
clean:
	-[ -f $(ENV_VARS) ] && rm $(ENV_VARS)
	-[ ! -z "$(DST_DIR)" ] && rm -rf $(DST_DIR)/*
	-[ ! -z "$(CACHE_DIR)" ] && rm -rf $(CACHE_DIR)/*
