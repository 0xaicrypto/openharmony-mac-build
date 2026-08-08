#ifndef _MNTENT_STUB_H
#define _MNTENT_STUB_H

#include <stdio.h>
#include <stdlib.h>

struct mntent {
	char *mnt_fsname;
	char *mnt_dir;
	char *mnt_type;
	char *mnt_opts;
	int mnt_freq;
	int mnt_passno;
};

static inline FILE *setmntent(const char *filename, const char *type)
{
	(void)filename;
	(void)type;
	return NULL;
}

static inline struct mntent *getmntent(FILE *stream)
{
	(void)stream;
	return NULL;
}

static inline int endmntent(FILE *stream)
{
	(void)stream;
	return 1;
}

static inline char *hasmntopt(struct mntent *mnt, const char *opt)
{
	(void)mnt;
	(void)opt;
	return NULL;
}

#endif
