
cconv.so: accell.h accell.c cconv.c
	cc -fPIC -shared -o $@ $<

all: cconv.so

clean:
	rm -f cconv.so
