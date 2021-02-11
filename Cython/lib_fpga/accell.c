#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "accell.h"

int allwrite(int fo, int *buf, int len);
int allread(int fi, int *buf, int len);

int file_write_patch;
int file_write_kernel;
int file_read;

//int openPatchStream()
//int openKernelStream()
//int openReadStream()

int openStreams(void)
{
    if(!(file_write_patch = open("/dev/xillybus_write_patch_32", O_WRONLY)))
    {
		fprintf(stderr, "\nError in opening /dev/xillybus_write_patch_32\n");
		return 1;
	}

    if(!(file_write_kernel = open("/dev/xillybus_write_kernel_32", O_WRONLY)))
	{
		fprintf(stderr, "\nError in opening /dev/xillybus_write_kernel_32\n");
		return 2;
	}
 
	if(!(file_read = open("/dev/xillybus_read_32", O_RDONLY)))
	{
		fprintf(stderr, "Error in opening /dev/xillybus_read_32\n");
		return 3;
	}
    return 0;
}

int writeKernel(int32_t* kernel, int length)
{
    return allwrite(file_write_kernel, kernel, length*sizeof(int32_t));
}

int writePatch(int32_t* patch, int length)
{
    return allwrite(file_write_patch, patch, length*sizeof(int32_t));
}

int readPixel(int32_t *pixel)
{
    return allread(file_read, pixel, sizeof(int32_t));
}

int allwrite(int fo, int *buf, int len)
{
	int sent = 0;
	int wc;

	while(sent < len) 
	{
		wc = write(fo, buf + sent, len - sent);

		if(wc == 0) 
		{
			fprintf(stderr, "Reached write EOF (?!)\n");
			return 1;
		}
		sent += wc;
	}
    return 0;
}

int allread(int fi, int *buf, int len)
{
	int read_data = 0;
	int rc;

	while(read_data < len)
	{
		rc = read(fi, buf + read_data, len - read_data);
		//fprintf(stderr,"rc: %d, ", rc);

		/*int j;
		for(j = 0; j < rc; j++)
		{
			fprintf(stderr,"b: %08x, ", *((unsigned char*)buf+read_data+j));
		}*/

		if(rc == 0)
		{
			fprintf(stderr, "Reached read EOF (?!)\n");
			return 1;
		}
		read_data += rc;
	}
    return 0;
}