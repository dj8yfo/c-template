LIB_SUFFIX=mylibname
LD_PATH=$(LD_LIBRARY_PATH):./build
CFLAGS=-g -O2 -Wall -Wextra -Isrc -rdynamic -DNDEBUG $(OPTFLAGS)
LIBS=-ldl $(OPTLIBS)
TESTS_LIB_FLAGS=-Lbuild -l$(LIB_SUFFIX)
PREFIX?=/usr/local

SOURCES=$(wildcard src/**/*.c src/*.c)
OBJECTS=$(patsubst %.c,%.o,$(SOURCES))

TEST_SRC=$(wildcard tests/*_tests.c)
TESTS=$(patsubst %.c,%,$(TEST_SRC))

PROGRAMS_SRC=$(wildcard bin/*.c)
PROGRAMS=$(patsubst %.c,%,$(PROGRAMS_SRC))

TARGET=build/lib$(LIB_SUFFIX).a
SO_TARGET=$(patsubst %.a,%.so,$(TARGET))

# The Target Build
all: $(TARGET) $(SO_TARGET) tests $(PROGRAMS)

%tests: %tests.c
	rc -c cc $(CFLAGS)  $^ $(TESTS_LIB_FLAGS) $(LIBS) -o $@
	cc $(CFLAGS) $^ $(TESTS_LIB_FLAGS) $(LIBS) -o $@

%main: %main.c
	rc -c cc $(CFLAGS)  $^ $(TESTS_LIB_FLAGS) $(LIBS) -o $@
	cc $(CFLAGS) $^ $(TESTS_LIB_FLAGS) $(LIBS) -o $@

%.o: %.c
	rc -c cc $(CFLAGS) -c $^  $(LIBS) -o $@
	cc -c $(CFLAGS) -c $^  $(LIBS) -o $@

dev: CFLAGS=-g -Wall -Isrc -Wall -Wextra $(OPTFLAGS)
dev: all

$(TARGET): CFLAGS += -fPIC
$(TARGET): build $(OBJECTS)
	ar rcs $@ $(OBJECTS)
	ranlib $@

$(SO_TARGET): $(TARGET) $(OBJECTS)
	$(CC) -shared -o $@ $(OBJECTS)

build:
	@mkdir -p build
	@mkdir -p bin

# The Unit Tests
.PHONY: tests
tests: $(TESTS)
	@echo echo LD_LIBRARY_PATH:
	@echo $(LD_PATH)
	LD_LIBRARY_PATH=$(LD_PATH) sh ./tests/runtests.sh

valgrind:
	VALGRIND="valgrind --log-file=/tmp/valgrind-%p.log" $(MAKE)

# The Cleaner
clean:
	rm -rf build $(OBJECTS) $(TESTS) $(PROGRAMS)
	rm -f tests/tests.log
	rm -f tests/*tests
	find . -name "*.gc*" -exec rm {} \;
	rm -rf `find . -name "*.dSYM" -print`

# The Install
install: all
	install -d $(DESTDIR)/$(PREFIX)/lib/
	install $(TARGET) $(DESTDIR)/$(PREFIX)/lib/

# The Checker
BADFUNCS='[^_.>a-zA-Z0-9](str(n?cpy|n?cat|xfrm|n?dup|str|pbrk|tok|_)|stpn?cpy|a?sn?printf|byte_)'
check:
	@echo Files with potentially dangerous functions.
	@egrep $(BADFUNCS) $(SOURCES) || true
