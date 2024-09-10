// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) E. K. Herman <eric@freesa.org>

#include "reproducible-sandbox-log.h"

#include <inttypes.h>
#include <string.h>

FILE *rsb_logger = NULL;

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
