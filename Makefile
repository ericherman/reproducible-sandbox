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

.PHONY: version
version:
	@echo VERSION: $(VERSION)

SOURCE_DATE_EPOCH ?= $(shell ./version-to-epoch $(VERSION))

.PHONY:source-date-epoch
source-date-epoch:
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

DIRS := build1 build2 debug1 debug2
$(DIRS):
	mkdir -pv $@

build1/reproducible-sandbox: reproducible-sandbox.c | build1
	$(CC) $(CFLAGS_BUILD) $^ -o $@

build1/reproducible-sandbox.out: build1/reproducible-sandbox
	$< > $@

build2/reproducible-sandbox: reproducible-sandbox.c | build2
	sleep 1.5
	$(CC) $(CFLAGS_BUILD) $^ -o $@

build2/reproducible-sandbox.out: build2/reproducible-sandbox
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

debug1/reproducible-sandbox: reproducible-sandbox.c | debug1
	$(CC) $(CFLAGS_DEBUG) $^ -o $@

debug1/reproducible-sandbox.out: debug1/reproducible-sandbox
	$< > $@

debug2/reproducible-sandbox: reproducible-sandbox.c | debug2
	sleep 1.5
	$(CC) $(CFLAGS_DEBUG) $^ -o $@

debug2/reproducible-sandbox.out: debug2/reproducible-sandbox
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

