// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) E. K. Herman <eric@freesa.org>

#include <errno.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#include "reproducible-sandbox-log.h"

// The location and value of uninitialized static variables in the binary
// could differ between compilations.
// Initialize for consistent results.
static uint32_t rsb_version = 1002003UL;
#define RSB_VERSION "1.2.3"

int main(void)
{
	Rsb_log("rsb version: %" PRIu32 " (%s)", rsb_version, RSB_VERSION);
	Rsb_log("   compiler: %s", __VERSION__);

	// The __DATE__ and __TIME__ macros make reproducibility harder
	Rsb_log("   __DATE__: %s", __DATE__);
	Rsb_log("   __TIME__: %s", __TIME__);

	// The __TIMESTAMP__ macro does not honor SOURCE_DATE_EPOCH,
	// rather it is the date/time of the last modification of __FILE__
	// and must be touch(1)ed to be made consistent.
	Rsb_log("   __TIMESTAMP__: %s", __TIMESTAMP__);

	return 0;
}
