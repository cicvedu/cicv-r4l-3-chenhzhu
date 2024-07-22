# ifneq ($(KERNELRELEASE),)

# # In kbuild context
# module-objs := rust_completion.o	
# obj-m := rust_completion.o

# CFLAGS_hello_world.o := -DDEBUG
# else
# KDIR := ../../../linux
# PWD := $(shell pwd)

# all:
# 	$(MAKE) LLVM=1 -C $(KDIR)  M=$(PWD) modules

# .PHONY: clean
# clean:
# 	rm -f *.ko *.o .*.cmd .*.o.d *.mod *.mod.o *.mod.c *.symvers *.markers *.unsigned *.order *~
# endif

KDIR ?= ../../../linux/

# Build Rust for Linux Module
LLVM?= 1

ifeq ($(LLVM), 1)
    RUSTC_FLAGS := $(RUSTC_FLAGS) -C opt-level=2 -C lto
endif

# Build the Rust kernel module
$(KDIR)/build:
	@echo Building Rust kernel module...
	$(MAKE) LLVM=$(LLVM) -C $(KDIR) M=$$PWD	