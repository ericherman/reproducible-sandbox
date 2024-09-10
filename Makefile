# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Eric Herman <eric@freesa.org>

default: check

# $@ : target label
# $< : the first prerequisite after the colon
# $^ : all of the prerequisite files
# $* : wildcard matched part

# |  : order-only prerequisites
#  https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html

# Target-specific Variable syntax:
# https://www.gnu.org/software/make/manual/html_node/Target_002dspecific.html

# patsubst : $(patsubst pattern,replacement,text)
#	https://www.gnu.org/software/make/manual/html_node/Text-Functions.html

SHELL := /bin/bash

# RSB_VERSION follows semver.org, e.g.: 3.11.1
VERSION := $(shell grep '#define RSB_VERSION "[0-9]*\.[0-9]*\.[0-9]*"' \
		src/reproducible-sandbox.c | cut -d'"' -f2)

.PHONY: version
version:
	@echo $(VERSION)

SOURCE_DATE_EPOCH ?= $(shell bin/version-to-epoch $(VERSION))

.PHONY:source-date-epoch
source-date-epoch:
	@echo $(SOURCE_DATE_EPOCH)

.PHONY:source-date-stamp
source-date-stamp:
	@date --utc '+%Y-%m-%d_%H-%M-%SZ' -d @$(SOURCE_DATE_EPOCH)

ALL_SRC=src/reproducible-sandbox.c \
	src/reproducible-sandbox-log.h \
	src/reproducible-sandbox-log.c

src/reproducible-sandbox-log.c: src/reproducible-sandbox-log.h
src/reproducible-sandbox.c: src/reproducible-sandbox-log.h


# the -fno-ident compiler option prevents adding unique ids to the binary
CC := SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) gcc -fno-ident

CFLAGS_NOISY := -Wall -Wextra -Wpedantic -Wcast-qual -Wc++-compat

CFLAGS_COMMON := -g $(CFLAGS_NOISY) $(CFLAGS)

CFLAGS_BUILD := -O2 -DNDEBUG $(CFLAGS_COMMON) -pipe

CFLAGS_DEBUG := -O0 \
	-fno-inline-small-functions \
	-fkeep-inline-functions \
	-fkeep-static-functions \
	$(CFLAGS_COMMON) --save-temps

# Target-specific Variables, CFLAGS:
build%: CFLAGS_BUILD_TYPE = $(CFLAGS_BUILD)
debug%: CFLAGS_BUILD_TYPE = $(CFLAGS_DEBUG)


# Use linker flags and options that enforce deterministic behavior:
LDFLAGS += -Wl,--no-undefined


# Target-specific Variables, sleep for a period on the second build:
build1%: SLEEP_SECONDS = 0
debug1%: SLEEP_SECONDS = 0
build2%: SLEEP_SECONDS = 2.5
debug2%: SLEEP_SECONDS = 2.5


BUILD_DIRS := build1 build2 debug1 debug2
$(BUILD_DIRS):
	mkdir -pv $@

%/reproducible-sandbox-log.o: src/reproducible-sandbox-log.c | %
	sleep $(SLEEP_SECONDS)
	echo $(SOURCE_DATE_EPOCH) > $@.epoch
	touch -d@$(SOURCE_DATE_EPOCH) $(ALL_SRC) $@.epoch
	$(CC) -c -fPIC $(CFLAGS_BUILD_TYPE) $^ -o $@

%/reproducible-sandbox: src/reproducible-sandbox.c \
		%/reproducible-sandbox-log.o
	$(CC) $(CFLAGS_BUILD_TYPE) $(LDFLAGS) $^ -o $@ $(LDADD)

%/reproducible-sandbox.out: %/reproducible-sandbox
	$< > $@ 2>&1

.PHONY: check-%-logs
check-%-logs: \
		%1/reproducible-sandbox-log.o \
		%2/reproducible-sandbox-log.o
	diff -u $^
	@echo SUCCESS $@

.PHONY: check-%-exes
check-%-exes: \
		%1/reproducible-sandbox \
		%2/reproducible-sandbox
	diff -u $^
	@echo SUCCESS $@

.PHONY: check-%-outs
check-%-outs: \
		%1/reproducible-sandbox.out \
		%2/reproducible-sandbox.out
	diff -u $^
	grep -q 1971 $<
	if grep $$(date +%Y) $<; then false; fi
	@echo SUCCESS $@

.PHONY: check
check: check-build-logs check-debug-logs \
	check-build-exes check-debug-exes \
	check-build-outs check-debug-outs
	@echo "SUCCESS $@"

LINDENT=indent -npro -kr -i8 -ts8 -sob -l80 -ss -ncs -cp1 -il0
.PHONY: tidy
tidy:
	$(LINDENT) -T FILE src/*.c src/*.h

# keep these for inspection
KEEPERS=reproducible-sandbox-log.o \
	reproducible-sandbox \
	reproducible-sandbox.out
KEEP := $(patsubst %, build1/%, $(KEEPERS)) \
	$(patsubst %, build2/%, $(KEEPERS)) \
	$(patsubst %, debug1/%, $(KEEPERS)) \
	$(patsubst %, debug2/%, $(KEEPERS))
.PRECIOUS: $(KEEP)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIRS)
