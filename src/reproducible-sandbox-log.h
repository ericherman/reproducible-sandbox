// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) E. K. Herman <eric@freesa.org>

#ifndef REPRODUCIBLE_SANDBOX_LOG_H
#define REPRODUCIBLE_SANDBOX_LOG_H

#include <errno.h>
#include <stdarg.h>
#include <stdio.h>

extern FILE *rsb_logger;

void rsb_log(FILE *log, const char *file, long line, const char *func,
	     int errnum, char *fmt, ...);

#define Rsb_log(...) \
	rsb_log(rsb_logger, __FILE__, __LINE__, __func__, errno, __VA_ARGS__)

#endif // #ifndef REPRODUCIBLE_SANDBOX_LOG_H
