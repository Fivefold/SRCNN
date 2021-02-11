
%.so: %.c
	cc -fPIC -shared -o $@ $<

all: cconv.so

clean:
	rm -f cconv.so
