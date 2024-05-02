// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) E. K. Herman <eric@freesa.org>

#include <errno.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#define RSB_VERSION "1.2.3"

FILE *rsb_logfile(void);
void rsb_log(FILE *log, const char *file, long line, const char *func,
	     int errnum, char *fmt, ...);

#define Rsb_log(...) \
	rsb_log(rsb_logfile(), __FILE__, __LINE__, __func__, errno, __VA_ARGS__)

int main(void)
{
	Rsb_log("rsb version: %s", RSB_VERSION);

	// The the __DATE__ and __TIME__ macros make reproducibility harder
	Rsb_log("   __DATE__: %s", __DATE__);
	Rsb_log("   __TIME__: %s", __TIME__);

	return 0;
}

FILE *rsb_logger = NULL;
FILE *rsb_logfile(void)
{
	return rsb_logger ? rsb_logger : stdout;
}

void rsb_log(FILE *log, const char *file, long line, const char *func,
	     int errnum, char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	fprintf(log, "%s +%ld %s(): ", file, line, func);
	if (errnum) {
		fprintf(log, "%s: ", strerror(errnum));
	}
	vfprintf(log, fmt, ap);
	fprintf(log, "\n");
	va_end(ap);
}
