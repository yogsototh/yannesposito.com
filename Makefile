# Static Site Generator Makefile
# ==============================
#
# Core concept: Define transformations from source files to destination files.
# Each transformation specifies: source pattern → destination pattern via recipe.

.DEFAULT_GOAL := site
.SECONDEXPANSION:

# ==============================================================================
# Configuration
# ==============================================================================
SRC_DIR   ?= src
DST_DIR   ?= _site
CACHE_DIR ?= .cache

NO_DRAFT := -not -path '$(SRC_DIR)/drafts/*'

# Accumulated build targets
ALL :=

# ==============================================================================
# Core Transformation Macros
# ==============================================================================

# transform: Define a 1:1 file transformation rule
#   $(1) = name (used for .PHONY target and variable prefix)
#   $(2) = source directory
#   $(3) = destination directory
#   $(4) = source extension (e.g., .org)
#   $(5) = destination extension (e.g., .html)
#   $(6) = extra find filters (optional, e.g., $(NO_DRAFT))
#   $(7) = extra dependencies (optional, e.g., template files)
#   $(8) = recipe (use $$< for source, $$@ for dest)
#
# Note: Use $(strip) to handle whitespace from backslash-continued $(call)
define transform
  _SRC_$(1) := $$(shell find $(strip $(2)) -type f -name '*$(strip $(4))' $(strip $(6)) 2>/dev/null)
  _DST_$(1) := $$(patsubst $(strip $(2))/%$(strip $(4)),$(strip $(3))/%$(strip $(5)),$$(_SRC_$(1)))

  $(strip $(3))/%$(strip $(5)): $(strip $(2))/%$(strip $(4)) $(strip $(7)) | $$$$(@D)/.dir
	$(strip $(8))

  .PHONY: $(1)
  $(1): $$(_DST_$(1))
  ALL += $(1)
endef

# copy_assets: Copy files matching a pattern (no extension change)
#   $(1) = name
#   $(2) = find filter for files to copy
define copy_assets
  _SRC_$(1) := $$(shell find $$(SRC_DIR) -type f $(2) 2>/dev/null)
  _DST_$(1) := $$(patsubst $$(SRC_DIR)/%,$$(DST_DIR)/%,$$(_SRC_$(1)))

  $$(DST_DIR)/%: $$(SRC_DIR)/% | $$$$(@D)/.dir
	@cp "$$<" "$$@"

  .PHONY: $(1)
  $(1): $$(_DST_$(1))
  ALL += $(1)
endef

# aggregate: Many input files → single output file
#   $(1) = name
#   $(2) = output file path
#   $(3) = input files (variable or list)
#   $(4) = extra dependencies
#   $(5) = recipe
define aggregate
  $(2): $(3) $(4) | $$$$(@D)/.dir
	$(5)

  .PHONY: $(1)
  $(1): $(2)
  ALL += $(1)
endef

# Directory creation (order-only prerequisite)
%/.dir:
	@mkdir -p $(@D)
	@touch $@

.PRECIOUS: %/.dir

# ==============================================================================
# Environment Setup
# ==============================================================================
ENV_VARS  := ./engine/envvars.sh
NIX_FILES := ./shell.nix $(wildcard nix/*)

$(ENV_VARS): $(NIX_FILES)
	@echo "export PATH=\"$(PATH)\"" > $@

ALL += envvars
.PHONY: envvars
envvars: $(ENV_VARS)

# ==============================================================================
# Transformations
# ==============================================================================

# --- Assets (copy non-source files) -------------------------------------------
$(eval $(call copy_assets,assets,$(NO_DRAFT) ! -name '*.org' ! -name '*.css'))

# --- CSS (minify) -------------------------------------------------------------
$(eval $(call transform,css,\
  $(SRC_DIR),$(DST_DIR),\
  .css,.css,\
  ,$(ENV_VARS),\
  @minify "$$<" > "$$@"))

# --- Images (optimize) --------------------------------------------------------
OPTIM_IMG := engine/optim-img.sh

$(foreach ext,jpg jpeg gif png,\
  $(eval $(call transform,$(ext),\
    $(SRC_DIR),$(DST_DIR),\
    .$(ext),.$(ext),\
    ,$(OPTIM_IMG) $(ENV_VARS),\
    @$$(OPTIM_IMG) "$$<" "$$@")))

.PHONY: img
img: jpg jpeg gif png

# --- HTML (org → html via pandoc) ---------------------------------------------
PANDOC_DEPS := templates/post.html \
               engine/links-to-html.lua \
               engine/img-to-webp.lua \
               engine/metas.lua \
               engine/mk-html.sh

$(eval $(call transform,html,\
  $(SRC_DIR),$(DST_DIR),\
  .org,.html,\
  $(NO_DRAFT),$(PANDOC_DEPS) $(ENV_VARS),\
  @engine/mk-html.sh templates/post.html engine/links-to-html.lua engine/img-to-webp.lua engine/metas.lua "$$<" "$$@.tmp" && \
   cat "$$@.tmp" | minify --type text/html > "$$@" && rm -f "$$@.tmp"))

# --- Gemini (org → gmi) -------------------------------------------------------
GMI_DEPS := engine/org2gemini.sh engine/org2gemini_step1.sh

$(eval $(call transform,gmi,\
  $(SRC_DIR),$(DST_DIR),\
  .org,.gmi,\
  $(NO_DRAFT),$(GMI_DEPS) $(ENV_VARS),\
  @engine/org2gemini.sh "$$<" "$$@"))

# ==============================================================================
# Index & Feed Generation (Posts Pipeline)
# ==============================================================================
# Pipeline: .org (source) → .html (built) → .xml (cache) → .index/.rss (cache) → index.html/rss.xml
#
# We derive all file lists from SOURCE .org files to ensure proper dependency tracking
# (intermediate files don't exist at make evaluation time)

POSTS_SRC   := $(SRC_DIR)/posts
POSTS_DST   := $(DST_DIR)/posts
POSTS_CACHE := $(CACHE_DIR)/rss

# Find all post source files (handles subdirectories)
_POST_ORGS := $(shell find $(POSTS_SRC) -name '*.org' 2>/dev/null)

# Derive all intermediate and final file paths from source
_POST_HTMLS   := $(patsubst $(POSTS_SRC)/%.org,$(POSTS_DST)/%.html,$(_POST_ORGS))
_POST_XMLS    := $(patsubst $(POSTS_SRC)/%.org,$(POSTS_CACHE)/%.xml,$(_POST_ORGS))
_POST_INDEXES := $(patsubst $(POSTS_SRC)/%.org,$(POSTS_CACHE)/%.index,$(_POST_ORGS))
_POST_RSSS    := $(patsubst $(POSTS_SRC)/%.org,$(POSTS_CACHE)/%.rss,$(_POST_ORGS))

# Step 1: html → xml (clean HTML for parsing)
$(POSTS_CACHE)/%.xml: $(POSTS_DST)/%.html $(ENV_VARS) | $$(@D)/.dir
	@hxclean "$<" > "$@"

# Step 2: xml → index entries
$(POSTS_CACHE)/%.index: $(POSTS_CACHE)/%.xml engine/mk-index-entry.sh $(ENV_VARS) | $$(@D)/.dir
	@engine/mk-index-entry.sh "$<" "$@"

# Step 3: xml → rss entries
$(POSTS_CACHE)/%.rss: $(POSTS_CACHE)/%.xml engine/mk-rss-entry.sh $(ENV_VARS) | $$(@D)/.dir
	@engine/mk-rss-entry.sh "$<" "$@"

# Aggregation: index entries → index.html
$(DST_DIR)/index.html: $(_POST_INDEXES) engine/mk-index.sh templates/index.html $(ENV_VARS) | $$(@D)/.dir
	@engine/mk-index.sh

# Aggregation: rss entries → rss.xml
$(DST_DIR)/rss.xml: $(_POST_RSSS) engine/mkrss.sh $(ENV_VARS) | $$(@D)/.dir
	@engine/mkrss.sh

.PHONY: index rss
index: $(DST_DIR)/index.html
rss: $(DST_DIR)/rss.xml
ALL += index rss

# ==============================================================================
# Gemini Index & Atom Feed
# ==============================================================================
_GMI_FILES := $(patsubst $(SRC_DIR)/%.org,$(DST_DIR)/%.gmi,$(shell find $(SRC_DIR) -name '*.org' $(NO_DRAFT) 2>/dev/null))

$(eval $(call aggregate,gmi-index,\
  $(DST_DIR)/index.gmi,\
  $(_GMI_FILES),\
  engine/mk-gemini-index.sh $(ENV_VARS),\
  @engine/mk-gemini-index.sh))

$(eval $(call aggregate,gmi-atom,\
  $(DST_DIR)/gem-atom.xml,\
  $(_GMI_FILES),\
  engine/mk-gemini-atom.sh $(ENV_VARS),\
  @engine/mk-gemini-atom.sh))

.PHONY: gemini
gemini: gmi gmi-index gmi-atom

# ==============================================================================
# Main Targets
# ==============================================================================
.PHONY: site deploy watch serve clean clean-html

site: $(ALL)

deploy: site
	@engine/sync.sh
	@engine/ye-com-fastpublish.hs

watch:
	@engine/watch.sh

serve:
	@engine/serve.sh

clean:
	@rm -f $(ENV_VARS)
	@rm -rf $(DST_DIR)/* $(CACHE_DIR)/*
	@find . -name '.dir' -delete

clean-html:
	@find $(DST_DIR) -name '*.html' -delete
	@rm -f $(DST_DIR)/index.html $(DST_DIR)/rss.xml
	@rm -rf $(CACHE_DIR)/rss

# Debug: show what would be built
.PHONY: debug
debug:
	@echo "ALL targets: $(ALL)"
	@echo "HTML files: $(_DST_html)"
	@echo "GMI files: $(_DST_gmi)"
	@echo "Image files: $(_DST_jpg) $(_DST_png)"
