
%.so: %.c
	cc -fPIC -shared -o $@ $<

objects = ./lib_cpu/cconv.so ./lib_fpga/cconv1.so ./lib_fpga/cconv2.so
all: $(objects)

clean:
	rm -f ./lib_cpu/cconv.so ./lib_fpga/cconv1.so ./lib_fpga/cconv2.so
