# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Eric Herman <eric@freesa.org>

default: check

# $@ : target label
# $< : the first prerequisite after the colon
# $^ : all of the prerequisite files
# $* : wildcard matched part

# |  : order-only prerequisites
#  https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html

SHELL := /bin/bash

# RSB_VERSION follows semver.org, e.g.: 3.11.1
VERSION := $(shell grep '#define RSB_VERSION "[0-9]*\.[0-9]*\.[0-9]*"' \
		reproducible-sandbox.c | cut -d'"' -f2)
VER_MAJOR := $(shell echo "$(VERSION)" | cut -f1 -d'.')
VER_MINOR := $(shell echo "$(VERSION)" | cut -f2 -d'.')
VER_PATCH := $(shell echo "$(VERSION)" | cut -f3 -d'.')

version:
	@echo VERSION: $(VERSION)
	@echo VER_MAJOR: $(VER_MAJOR)
	@echo VER_MINOR: $(VER_MINOR)
	@echo VER_PATCH: $(VER_PATCH)

SOURCE_DATE_YEAR := $(shell echo $$(( 2000 + $(VER_MAJOR) )))
SOURCE_DATE_DATE := $(shell date --utc --iso-8601=s \
	-d'$(SOURCE_DATE_YEAR)-01-01 +$(VER_MINOR) days')
SOURCE_DATE_TIME := $(shell date --utc --iso-8601=s \
	-d'$(SOURCE_DATE_DATE) +$(VER_PATCH) seconds')
SOURCE_DATE_EPOCH ?= $(shell date --utc -d'$(SOURCE_DATE_TIME)' +'%s')

.PHONY:source-date-epoch
source-date-epoch:
	@echo SOURCE_DATE_YEAR:$(SOURCE_DATE_YEAR)
	@echo SOURCE_DATE_DATE:$(SOURCE_DATE_DATE)
	@echo SOURCE_DATE_TIME:$(SOURCE_DATE_TIME)
	@echo SOURCE_DATE_EPOCH:$(SOURCE_DATE_EPOCH)
	date --utc '+%Y-%m-%d_%H-%M-%SZ' -d @$(SOURCE_DATE_EPOCH)

CC := SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) gcc

CFLAGS_NOISY := -Wall -Wextra -Wpedantic -Wcast-qual -Wc++-compat \
		$(CFLAGS) -pipe

CFLAGS_COMMON := -g $(CFLAGS_NOISY)

CFLAGS_BUILD := -O2 -DNDEBUG $(CFLAGS_COMMON)

CFLAGS_DEBUG := -O0 \
	-fno-inline-small-functions \
	-fkeep-inline-functions \
	-fkeep-static-functions \
	$(CFLAGS_COMMON)

build1:
	mkdir -pv build1

build1/reproducible-sandbox: reproducible-sandbox.c | build1
	$(CC) $(CFLAGS_BUILD) $^ -o $@

build1/reproducible-sandbox.out: build1/reproducible-sandbox | build1
	$< > $@

build2:
	mkdir -pv build2

build2/reproducible-sandbox: reproducible-sandbox.c | build2
	sleep 1.5
	$(CC) $(CFLAGS_BUILD) $^ -o $@

build2/reproducible-sandbox.out: build2/reproducible-sandbox | build2
	$< > $@

.PHONY: check-build1-build2
check-build1-build2: \
		build1/reproducible-sandbox \
		build2/reproducible-sandbox
	diff -u $^
	@echo SUCCESS $@

.PHONY: check-build1-build2-out
check-build1-build2-out: \
		build1/reproducible-sandbox.out \
		build2/reproducible-sandbox.out
	diff -u $^
	@echo SUCCESS $@

debug1:
	mkdir -pv debug1

debug1/reproducible-sandbox: reproducible-sandbox.c | debug1
	$(CC) $(CFLAGS_DEBUG) $^ -o $@

debug1/reproducible-sandbox.out: debug1/reproducible-sandbox | debug1
	$< > $@

debug2:
	mkdir -pv debug2

debug2/reproducible-sandbox: reproducible-sandbox.c | debug2
	sleep 1.5
	$(CC) $(CFLAGS_DEBUG) $^ -o $@

debug2/reproducible-sandbox.out: debug2/reproducible-sandbox | debug2
	$< > $@


.PHONY: check-debug1-debug2
check-debug1-debug2: \
		debug1/reproducible-sandbox \
		debug2/reproducible-sandbox
	diff -u $^
	@echo SUCCESS $@

.PHONY: check-debug1-debug2-out
check-debug1-debug2-out: \
		debug1/reproducible-sandbox.out \
		debug2/reproducible-sandbox.out
	diff -u $^
	@echo SUCCESS $@

.PHONY: check
check: check-build1-build2-out check-debug1-debug2-out \
		check-build1-build2 check-debug1-debug2
	@echo "SUCCESS $@"

LINDENT=indent -npro -kr -i8 -ts8 -sob -l80 -ss -ncs -cp1 -il0
.PHONY: tidy
tidy:
	$(LINDENT) -T FILE *.c

.PHONY: clean
clean:
	rm -rf build1 build2 debug1 debug2

