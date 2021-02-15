
%.so: %.c
	cc -fPIC -shared -o $@ $<

all: cconv2.so

clean:
	rm -f cconv2.so
