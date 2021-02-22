
#include <stdlib.h>
#include <stdio.h>

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


conv_t* cconv(conv_t *input, conv_t *kernels, conv_t *biases,
    u_int8_t numChannelIn, u_int8_t numChannelOut, u_int8_t kernelSize, u_int16_t height, u_int16_t width) {

    //initialize output array
    conv_t *output = calloc(width * height * numChannelOut, sizeof(conv_t));
    int kSizeHalf = kernelSize/2;
    int kSizeSquared = kernelSize * kernelSize;

    FILE *i_file;
    FILE *k_file;
    FILE *o_file;

    i_file = fopen("input.txt", "wb");
    if(i_file == NULL) {
        printf("Can't open file input.txt");
        free(output);
        exit(1);
    }
    k_file = fopen("kernel.txt", "wb");
    if(k_file == NULL) {
        printf("Can't open file kernel.txt");
        free(output);
        exit(1);
    }
    o_file = fopen("output.txt", "wb");
    if(o_file == NULL) {
        printf("Can't open file output.txt");
        free(output);
        exit(1);
    }

    //convolution loops
    for(int k = 0; k < numChannelOut; ++k) {
        for(int n = 0; n < numChannelIn; ++n) {
            for(int i = 0; i < height; ++i) {
                for(int j = 0; j < width; ++j) {
                    
                    fprintf(i_file, "%X\n", input[(n*height*width) + (y*width) + x]);

                    conv_t sum = 0;

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

                            fprintf(k_file, "%X\n", kernels[(k*numChannelIn*kSizeSquared) + (n*kSizeSquared) + (l*kernelSize) + m]);

                            sum += fp_mul(input[(n*height*width) + (y*width) + x], kernels[(k*numChannelIn*kSizeSquared) + (n*kSizeSquared) + (l*kernelSize) + m]);
                        }
                    }
                    fprintf(o_file, "%X\n", sum);
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

    fclose(i_file);
    fclose(k_file);
    fclose(o_file);

    return output;
} 
