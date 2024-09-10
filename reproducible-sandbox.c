// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) E. K. Herman <eric@freesa.org>

#include <errno.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>


// The location and value of uninitialized static variables in the binary
// could differ between compilations.
// Initialize for consistent results.
static uint32_t rsb_version = 1002003UL;
#define RSB_VERSION "1.2.3"

FILE *rsb_logger = NULL;

void rsb_log(FILE *log, const char *file, long line, const char *func,
	     int errnum, char *fmt, ...);

#define Rsb_log(...) \
	rsb_log(rsb_logger, __FILE__, __LINE__, __func__, errno, __VA_ARGS__)

int main(void)
{
	Rsb_log("rsb version: %"PRIu32" (%s)", rsb_version, RSB_VERSION);
	Rsb_log("   compiler: %s", __VERSION__);

	// The __DATE__ and __TIME__ macros make reproducibility harder
	Rsb_log("   __DATE__: %s", __DATE__);
	Rsb_log("   __TIME__: %s", __TIME__);

	return 0;
}

void rsb_log(FILE *log, const char *file, long line, const char *func,
	     int errnum, char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);

	log = log ? log : stderr;

	fprintf(log, "%s +%ld %s(): ", file, line, func);
	if (errnum) {
		fprintf(log, "%s: ", strerror(errnum));
	}
	vfprintf(log, fmt, ap);
	fprintf(log, "\n");
	va_end(ap);
}
