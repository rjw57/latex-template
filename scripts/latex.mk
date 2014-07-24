PWD:=$(shell pwd)

# The following variables may be overridden on the make command line
PERL ?= perl
LATEXMK ?= $(PERL) $(PWD)/scripts/latexmk.pl
BUILD_DIR ?= $(PWD)/build
OUTPUT_DIR ?= pdf
FFMPEG ?= ffmpeg
PDFLATEX ?= xelatex
TEXLOCAL_DIR ?= texlocal

LATEXMK_CMD:=$(LATEXMK) -bibtex -pdf \
	-pdflatex="$(PDFLATEX) -interaction=nonstopmode -file-line-error -halt-on-error %O %S"

POSTER_DIR:=$(BUILD_DIR)/poster
LOCAL_PACKAGES:=$(EXTRA_PACKAGES) $(wildcard $(TEXLOCAL_DIR)/*)

COMMON_TEXINPUTS_LIST:=$(addprefix $(PWD)/, $(LOCAL_PACKAGES))
COMMON_TEXINPUTS_LIST+=$(addprefix $(POSTER_DIR)/, $(LOCAL_PACKAGES))

# https://stackoverflow.com/questions/10571658/gnu-make-convert-spaces-to-colons
empty :=
space := $(empty) $(empty)

COMMON_TEXINPUTS:=$(subst $(space),:,$(COMMON_TEXINPUTS_LIST))

.PHONY: pdfs
pdfs: $(addprefix $(OUTPUT_DIR)/, $(PDFS))

define PDF_template
$(1:.pdf=)_PDF_OUTPUT := $(addprefix $(OUTPUT_DIR)/, $(1))
$(1:.pdf=)_PDF_OUTPUT_DIR := $(dir $(addprefix $(OUTPUT_DIR)/, $(1)))
$(1:.pdf=)_BUILD_PDF := $(patsubst %.tex, $(BUILD_DIR)/%.pdf, $(value $(1:.pdf=)_TEX))
$(1:.pdf=)_BUILD_POSTERS := $(patsubst %.mp4, $(POSTER_DIR)/%.jpg, $(value $(1:.pdf=)_VIDEOS))

$(1:.pdf=)_PDF_DEPENDS+=$$($(1:.pdf=)_BUILD_POSTERS)

$$($(1:.pdf=)_BUILD_PDF): $$($(1:.pdf=)_DEPENDS) $$($(1:.pdf=)_PDF_DEPENDS)

$$($(1:.pdf=)_PDF_OUTPUT): $$($(1:.pdf=)_BUILD_PDF)
	mkdir -p $$($(1:.pdf=)_PDF_OUTPUT_DIR)
	cp "$$($(1:.pdf=)_BUILD_PDF)" "$$($(1:.pdf=)_PDF_OUTPUT)"

.PHONY: $(1:.pdf=)
$(1:.pdf=): $$($(1:.pdf=)_PDF_OUTPUT)
endef

$(foreach pdf, $(PDFS), $(eval $(call PDF_template, $(pdf))))

.PHONY: clean
clean:
	rm -rf "$(BUILD_DIR)" "$(OUTPUT_DIR)"

$(POSTER_DIR)/%.jpg: %.mp4
	mkdir -p "$(dir $@)"
	$(FFMPEG) -i "$<" -ss 00:00:2.1 -f image2 -vframes 1 "$@"

$(BUILD_DIR)/%.pdf: TEXINPUTS=$(BUILD_DIR)/$(dir $<):$(POSTER_DIR)/$(dir $<):$(COMMON_TEXINPUTS)
$(BUILD_DIR)/%.pdf: BUILD_ROOT=$(BUILD_DIR)/$*
$(BUILD_DIR)/%.pdf: %.tex
	mkdir -p "$(BUILD_ROOT)"
	rm -f "$(BUILD_ROOT)/$(notdir $*).pdf"
	cd "$(dir $<)" && TEXINPUTS="$$TEXINPUTS:$(TEXINPUTS)" BIBINPUTS="$$BIBINPUTS:$(TEXINPUTS)" \
		 $(LATEXMK_CMD) -outdir="$(BUILD_ROOT)" "$(notdir $<)"
	mkdir -p "$(dir $@)"
	cp "$(BUILD_ROOT)/$(notdir $*).pdf" "$@"
