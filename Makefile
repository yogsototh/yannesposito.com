# Generate my website out of org-mode/gemini files
#
# maybe check https://themattchan.com/blog/2017-02-28-make-site-generator.html

source := src
output := _site
sources := $(shell find $(source) -name '*.org')
htmls := $(patsubst %.org,%.html,$(subst $(source),$(output),$(sources)))

assetssources := $(shell find $(source) -type f ! -path '*.org')
assets := $(subst $(source),$(output),$(assetssources)) 

all: $(htmls) $(assets)

$(output)/%.css: $(source)/%.css
 	mkdir -p $(shell dirname $@)
	cp $< $@

# # recipe for converting an org-mode file into html using Pandoc
# $(output)/%.html: $(source)/%.org
# 	mkdir -p $(shell dirname $@)
# 	pandoc \
# 		--from org \
# 		--to html5 \
# 		--css=/css/y.css \
# 		--toc \
# 		-s \
# 		--standalone \
# 		$< \
# 		-o $@

.PHONY: clean

clean:
	rm -rf $(output)/*
