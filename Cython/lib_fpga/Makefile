
%.so: %.c
	cc -Wall -fPIC -shared -o $@ $<

all: cconv1.so cconv2.so

clean:
	rm -f cconv1.so
	rm -f cconv2.so
