// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) E. K. Herman <eric@freesa.org>

#include <errno.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>


#define RSB_VERSION "1.2.3"

FILE *rsb_logger = NULL;

void rsb_log(FILE *log, const char *file, long line, const char *func,
	     int errnum, char *fmt, ...);

#define Rsb_log(...) \
	rsb_log(rsb_logger, __FILE__, __LINE__, __func__, errno, __VA_ARGS__)

int main(void)
{
	Rsb_log("rsb version: %s", RSB_VERSION);

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
