#ifndef __ACCELL_CCONV__
#define __ACCELL_CCONV__

#include <stdlib.h>

int openStreams(void);
int writePatch(int32_t* patch, int length);
int writeKernel(int32_t* kernel, int length);
int readPixel(int32_t *pixel);

#endif