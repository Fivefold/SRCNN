#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

typedef int32_t fp_t;

#define FP_FRACT_BITS 26
#define _INT_TO_FP(x) ((fp_t)(x << FP_FRACT_BITS))
#define _FLOAT_TO_FP(x) ((fp_t)(x * (1 << FP_FRACT_BITS)))
#define _FP_TO_FLOAT(x) ((float)x / (float)(1 << FP_FRACT_BITS))

//#define conv_t float
#define conv_t fp_t

#define _FP_MUL(a,b) (fp_t) (((int64_t) a * b) >> FP_FRACT_BITS)

static inline fp_t float2fp(float f) {
    return _FLOAT_TO_FP(f);
}

static inline float fp2float(fp_t x) {
    return _FP_TO_FLOAT(x);
}

static inline fp_t fp_mul(fp_t a, fp_t b) {
    return _FP_MUL(a, b);
}

int openStreams(void);
int writePatch(int32_t* patch, int length);
int writeKernel(int32_t* kernel, int length);
int readPixel(int32_t *pixel);

int allwrite(int fo, int *buf, int len);
int allread(int fi, int *buf, int len);

int file_write_patch;
int file_write_kernel;
int file_read;


conv_t* cconv2(conv_t *input, conv_t *kernels, conv_t *biases,
    u_int8_t numChannelIn, u_int8_t numChannelOut, u_int8_t kernelSize, u_int16_t height, u_int16_t width) {

    //initialize output array
    conv_t *output = calloc(width * height * numChannelOut, sizeof(conv_t));
    int kSizeHalf = kernelSize/2;
    int kSizeSquared = kernelSize * kernelSize;

    conv_t patch[kSizeSquared];

    openStreams();
    printf("Starting convolution with FPGA support...\n");

    //convolution loops
    for(int k = 0; k < numChannelOut; ++k) {
        for(int n = 0; n < numChannelIn; ++n) {

            //it would be possible to write kernel here if it is stored on PL
            //writeKernel(kernels + k*numChannelIn*kSizeSquared + n*kSizeSquared, kSizeSquared);

            for(int i = 0; i < height; ++i) {
                for(int j = 0; j < width; ++j) {
                    

                    conv_t sum = 0;

                    if(writeKernel(kernels + k*numChannelIn*kSizeSquared + n*kSizeSquared, kSizeSquared)) exit(1);

                    for(int l = 0; l < kernelSize; ++l) {
                        for(int m = 0; m < kernelSize; ++m) {

                            int y = i - kSizeHalf + l;
                            int x = j - kSizeHalf + m;

                            /*
                            //zero padding check
                            if((y >= 0) && (x >= 0) && (y < height) && (x < width)) {
                                sum += input[(n*height*width) + (y*width) + x] * kernels[(k*numChannelIn*kSizeSquared) + (n*kSizeSquared) + (l*kernelSize) + m];
                            } */

                            //padding checks
                            if(y < 0) y = 0;
                            if(x < 0) x = 0;
                            if(y >= height) y = height - 1;
                            if(x >= width) x = width - 1;

                            patch[(l*kernelSize) + m] = input[(n*height*width) + (y*width) + x];
                            //sum += fp_mul(input[(n*height*width) + (y*width) + x], kernels[(k*numChannelIn*kSizeSquared) + (n*kSizeSquared) + (l*kernelSize) + m]);
                        }
                    }
                    writePatch(patch, kSizeSquared);
                    readPixel(&sum);

                    output[(k*height*width) + (i*width) + j] += sum;
                }
            }
        }

        for(int i = 0; i < height; ++i) {
            for(int j = 0; j < width; ++j) {
                //adding biases
                conv_t value = output[(k*height*width) + (i*width) + j] + biases[k];
                //RELU
                if(value < 0) {
                    value = 0;
                }
                //writeback
                output[(k*height*width) + (i*width) + j] = value;
            }
        }
    }

    return output;
} 

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
