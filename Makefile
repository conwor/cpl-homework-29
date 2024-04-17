# =============================================================================
# Variables

# Build tools and options
GCC = gcc
MAIN_FLAGS = -std=c99 -g -O0
WARNINGS_FLAGS = -Wall -Wextra -Wpedantic -Wduplicated-branches -Wduplicated-cond -Werror=cast-qual -Wconversion -Wsign-conversion -Wlogical-op -Werror

# Task-specific patch
# SANITIZER_FLAGS = -fsanitize=address -fsanitize=pointer-compare -fsanitize=pointer-subtract -fsanitize=leak -fsanitize=undefined -fsanitize-address-use-after-scope
SANITIZER_FLAGS = -fsanitize=undefined -fsanitize-address-use-after-scope

FLAGS = $(MAIN_FLAGS) $(WARNINGS_FLAGS) $(SANITIZER_FLAGS)

# Sources and headers
SOURCES = $(wildcard ./*.c)
HEADERS = $(wildcard ./*.h)
FORMATTED_FILES = $(SOURCES:.c=.c.formatted) $(HEADERS:.h=.h.formatted)

# Targets
EXE_32_STD_ALLOC = main-32-std-alloc
EXE_64_STD_ALLOC = main-64-std-alloc
EXE_32 = main-32
EXE_64 = main-64

# Tests
IN = $(wildcard tests/*-input.txt)
ACT_32_STD_ALLOC = $(IN:-input.txt=-actual-32-std-alloc.txt)
ACT_64_STD_ALLOC = $(IN:-input.txt=-actual-64-std-alloc.txt)
ACT_32 = $(IN:-input.txt=-actual-32.txt)
ACT_64 = $(IN:-input.txt=-actual-64.txt)
PASS = $(IN:-input.txt=.passed)


# =============================================================================
# Tasks

all: clean-before test clean-after

$(FORMATTED_FILES): %.formatted: %
	@clang-format --style=file $* > $*.formatted
	diff $* $*.formatted

$(EXE_32_STD_ALLOC): $(FORMATTED_FILES)
	@rm -f $(FORMATTED_FILES)
	$(GCC) $(FLAGS) $(SOURCES) -o $@ -m32 -D USE_STD_ALLOC

$(EXE_64_STD_ALLOC): $(FORMATTED_FILES)
	@rm -f $(FORMATTED_FILES)
	$(GCC) $(FLAGS) $(SOURCES) -o $@ -m64 -D USE_STD_ALLOC

$(EXE_32): $(FORMATTED_FILES)
	@rm -f $(FORMATTED_FILES)
	$(GCC) $(FLAGS) $(SOURCES) -o $@ -m32

$(EXE_64): $(FORMATTED_FILES)
	@rm -f $(FORMATTED_FILES)
	$(GCC) $(FLAGS) $(SOURCES) -o $@ -m64

$(PASS): %.passed: %-input.txt %-expected.txt  $(EXE_32_STD_ALLOC) $(EXE_64_STD_ALLOC) $(EXE_32) $(EXE_64)
	@echo "Running test $*..."
	@rm -f $@
	./$(EXE_32_STD_ALLOC) < $*-input.txt 1> $*-actual-32-std-alloc.txt 2>&1
	diff $*-expected.txt $*-actual-32-std-alloc.txt
	./$(EXE_64_STD_ALLOC) < $*-input.txt 1> $*-actual-64-std-alloc.txt 2>&1
	diff $*-expected.txt $*-actual-64-std-alloc.txt
	./$(EXE_32) < $*-input.txt 1> $*-actual-32.txt 2>&1
	diff $*-expected.txt $*-actual-32.txt
	./$(EXE_64) < $*-input.txt 1> $*-actual-64.txt 2>&1
	diff $*-expected.txt $*-actual-64.txt
	@touch $@

test: $(PASS)
	@echo "All tests passed"

clean-before:
	rm -f $(FORMATTED_FILES) $(EXE)

clean-after:
	rm -f $(ACT_32_STD_ALLOC) $(ACT_64_STD_ALLOC) $(ACT_32) $(ACT_64) $(PASS)

.PHONY: all test clean
