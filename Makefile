# Specify output PDF documents here.
PDFS:=example_presentation.pdf example_paper.pdf

# Sources common to all documents:
common_depends:=$(wildcard common/fig/*)
common_videos:=$(wildcard common/video/*)

# Add the common directory to the common texinputs.
# NOTE: this list is *space* separated
EXTRA_PACKAGES:=common

# Sources for each document:

# Presentation has no references...
example_presentation_TEX:=presentation/presentation.tex
example_presentation_DEPENDS:=$(common_depends)
example_presentation_VIDEOS:=\
	$(wildcard presentation/video/*) $(common_videos)

# Paper does so we need to add an extra dependency...
example_paper_TEX:=paper/paper.tex
example_paper_DEPENDS:=$(wildcard paper/*.bib) $(common_depends)
example_paper_VIDEOS:=$(wildcard paper/video/*) $(common_videos)

# The magic is in here.
include scripts/latex.mk
