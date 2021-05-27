files := $(wildcard *.lua)
names := $(files:.lua=)

.PHONY: all clean $(names)

all: $(names)

$(names): %: bin/%

bin/%: %.lua build-binary.sh Makefile
	mkdir -p bin
	./build-binary.sh $<
	mv $(@F) bin/

clean:
	rm -rf bin
