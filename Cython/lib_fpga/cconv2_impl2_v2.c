#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>

typedef int32_t fp_t;

#define FP_FRACT_BITS 26
#define _INT_TO_FP(x) ((fp_t)(x << FP_FRACT_BITS))
#define _FLOAT_TO_FP(x) ((fp_t)(x * (1 << FP_FRACT_BITS)))
#define _FP_TO_FLOAT(x) ((float)x / (float)(1 << FP_FRACT_BITS))

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
int writeFeature(int32_t* feature, int length);
int writeKernel(int32_t* kernel, int length);
int readPixel(int32_t *pixel, int length);

int writeByte(int fi, unsigned char *buf);
int allwrite(int fo, int *buf, int len);
int allread(int fi, int *buf, int len);

int writeKernelProcess(conv_t *kernels, u_int8_t numChannelIn, u_int8_t numChannelOut,
    u_int8_t kernelSize, u_int16_t height, u_int16_t width);
int writeFeatureProcess(conv_t *input, u_int8_t numChannelIn, u_int8_t numChannelOut,
    u_int8_t kernelSize, u_int16_t height, u_int16_t width);
int readProcess(conv_t *biases, u_int8_t numChannelIn, u_int8_t numChannelOut,
    u_int16_t height, u_int16_t width);

int file_config;
int file_cmd;
int file_write_feature;
int file_write_kernel;
int file_read;

conv_t *output;
conv_t *result_feature;

void sigintHandlerWriteKernel(int sig)
{
    close(file_write_kernel);
    exit(1);
}

void sigintHandlerWriteFeature(int sig)
{
    close(file_write_feature);
    close(file_cmd);
    exit(1);
}

void sigintHandlerRead(int sig)
{
    close(file_read);
    close(file_config);
    free(result_feature);
    free(output);

    if(sig == SIGINT)
    {
        printf("Ctrl + C catched! Aborting...\n");
    }
    exit(1);
}

int writeKernelProcess(conv_t *kernels, u_int8_t numChannelIn, u_int8_t numChannelOut,
    u_int8_t kernelSize, u_int16_t height, u_int16_t width)
{
    int kSizeSquared = kernelSize * kernelSize;

    signal(SIGINT, sigintHandlerWriteKernel);
    signal(SIGUSR1, sigintHandlerWriteKernel);

    close(file_config);

    if(!(file_write_kernel = open("/dev/xillybus_write_kernel_32", O_WRONLY)))
	{
		fprintf(stderr, "\nError in opening /dev/xillybus_write_kernel_32\n");
        kill(-getpgid(0), SIGUSR1);
	}
    printf("Write kernel stream is open.\n");

    for(int n = 0; n < numChannelIn; ++n) {
        for(int k = 0; k < numChannelOut; ++k) {
            writeKernel(kernels + k*numChannelIn*kSizeSquared + n*kSizeSquared, kSizeSquared);
        }
    }

    close(file_write_kernel);
    return 0;
}

int writeFeatureProcess(conv_t *input, u_int8_t numChannelIn, u_int8_t numChannelOut,
    u_int8_t kernelSize, u_int16_t height, u_int16_t width)
{
    unsigned char dummy = 1;

    signal(SIGINT, sigintHandlerWriteFeature);
    signal(SIGUSR1, sigintHandlerWriteFeature);

    close(file_config);

    if(!(file_cmd = open("/dev/xillybus_command", O_WRONLY)))
    {
		fprintf(stderr, "\nError in opening /dev/xillybus_command\n");
        kill(-getpgid(0), SIGUSR1);
	}

    if(!(file_write_feature = open("/dev/xillybus_write_feature_32", O_WRONLY)))
    {
		fprintf(stderr, "\nError in opening /dev/xillybus_write_feature_32\n");
        kill(-getpgid(0), SIGUSR1);
	}

    printf("Write feature stream is open.\n");


    for(int n = 0; n < numChannelIn; ++n) {

        writeFeature(input + n * height * width, height * width);

        for(int k = 1; k < numChannelOut; ++k) {
            writeByte(file_cmd, &dummy);
        }


        /*for(int k = 0; k < numChannelOut; ++k) {
            writeFeature(input + n * height * width, height * width);
        }*/
    }

    close(file_cmd);
    close(file_write_feature);
    return 0;
}

int readProcess(conv_t *biases, u_int8_t numChannelIn, u_int8_t numChannelOut,
    u_int16_t height, u_int16_t width)
{
    signal(SIGINT, sigintHandlerRead);
    signal(SIGUSR1, sigintHandlerRead);

    result_feature = malloc(width * height * numChannelOut * sizeof(conv_t));

    if(!(file_read = open("/dev/xillybus_read_32", O_RDONLY)))
	{
		fprintf(stderr, "Error in opening /dev/xillybus_read_32\n");
        kill(-getpgid(0), SIGUSR1);
	}
    printf("Read stream is open.\n");

    //convolution loops
    for(int n = 0; n < numChannelIn; ++n) {
        //printf("n = %d\n", n);
        for(int k = 0; k < numChannelOut; ++k) {
            printf("k = %d\n", k);
            
            readPixel(result_feature, height * width);

            for(int i = 0; i < height; ++i) {

                for(int j = 0; j < width; ++j) {

                    //conv_t sum;
                    //readPixel(&sum, 1);
                    //output[(k*height*width) + (i*width) + j] += sum;

                    output[(k*height*width) + (i*width) + j] += result_feature[(i*width) + j];
                }
            }
        }
    }

    for(int k = 0; k < numChannelOut; ++k) {
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

    free(result_feature);
    close(file_read);
    return 0;
}

conv_t* cconv2(conv_t *input, conv_t *kernels, conv_t *biases,
    u_int8_t numChannelIn, u_int8_t numChannelOut, u_int8_t kernelSize, u_int16_t height, u_int16_t width) {

    int32_t config_array[3] = {(int32_t)width, (int32_t)height, (int32_t)kernelSize};

    //initialize output array
    output = calloc(width * height * numChannelOut, sizeof(conv_t));

    //open config interface
    if(!(file_config = open("/dev/xillybus_config", O_WRONLY)))
	{
		fprintf(stderr, "Error in opening /dev/xillybus_config\n");
        free(output);
        exit(1);
	}

    if(lseek(file_config, 0, SEEK_SET) < 0) {
        fprintf(stderr, "Error in searching address at /dev/xillybus_config\n");
        free(output);
        close(file_config);
        exit(1);
    }
    allwrite(file_config, config_array, 3 * sizeof(int32_t));
    
    switch(fork()) {
        case -1:
            fprintf(stderr, "\nError while forking!\n");
            kill(-getpgid(0), SIGUSR1);
            break;
        case 0:
            //child process is patch writer process
            writeFeatureProcess(input, numChannelIn, numChannelOut, kernelSize, height, width);
            exit(EXIT_SUCCESS);
        default:
            //parent process

            switch(fork()) {
                case -1:
                    fprintf(stderr, "\nError while forking!\n");
                    kill(-getpgid(0), SIGUSR1);
                    break;
                case 0:
                    //2nd child process is kernel writer process
                    writeKernelProcess(kernels, numChannelIn, numChannelOut, kernelSize, height, width);
                    exit(EXIT_SUCCESS);
                default:
                    //parent process is reader process
                    readProcess(biases, numChannelIn, numChannelOut, height, width);
            } 
    }

    close(file_config);
    return output;
} 



int writeKernel(int32_t* kernel, int length)
{
    return allwrite(file_write_kernel, kernel, length*sizeof(int32_t));
}

int writeFeature(int32_t* feature, int length)
{
    return allwrite(file_write_feature, feature, length*sizeof(int32_t));
}

int readPixel(int32_t *pixel, int length)
{
    return allread(file_read, pixel, length*sizeof(int32_t));
}

int writeByte(int fi, unsigned char *buf)
{
    int wc = write(fi, buf, 1);

    if(wc == 0) 
    {
        fprintf(stderr, "Reached write EOF (?!)\n");
        kill(-getpgid(0), SIGUSR1);
    }
    return 0;
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
            kill(-getpgid(0), SIGUSR1);
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

		if(rc == 0)
		{
			fprintf(stderr, "Reached read EOF (?!)\n");
            kill(-getpgid(0), SIGUSR1);
		}
		read_data += rc;
	}
    return 0;
}
