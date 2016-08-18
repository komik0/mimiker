# vim: tabstop=8 shiftwidth=8 noexpandtab:

include Makefile.common

CPPFLAGS += -Iinclude
LDLIBS   += kernel.a -Llibkern -lkern -lgcc

TESTS = callout.elf malloc.elf pmap.elf physmem.elf rtc.elf thread.elf \
	vm_map.elf runq.test sched.elf
SOURCES_C = startup.c uart_cbus.c interrupts.c clock.c malloc.c context.c \
	    physmem.c rtc.c pci.c pci_ids.c callout.c runq.c tlb.c pmap.c \
	    thread.c vm_pager.c vm_object.c vm_map.c sched.c
SOURCES_ASM = boot.S intr.S context-mips.S tlb-mips.S
SOURCES_ASM = boot.S context-mips.S tlb-mips.S
SOURCES = $(SOURCES_C) $(SOURCES_ASM)
OBJECTS = $(SOURCES_C:.c=.o) $(SOURCES_ASM:.S=.o)
DEPFILES = $(SOURCES_C:%.c=.%.D) $(SOURCES_ASM:%.S=.%.D)
# Kernel runtime files
KRT = kernel.a intr.o

all: $(DEPFILES) ctags cscope libkern $(TESTS)

callout.elf: callout.ko $(KRT)
thread.elf: thread.ko $(KRT)
malloc.elf: malloc.ko $(KRT)
rtc.elf: rtc.ko $(KRT)
context.elf: context.ko $(KRT)
vm_map.elf: vm_map.ko $(KRT)
physmem.elf: physmem.ko $(KRT)
sched.elf: sched.ko $(KRT)
kernel.a: $(OBJECTS)

$(foreach file,$(SOURCES) null,$(eval $(call emit_dep_rule,$(file))))

ifeq ($(words $(findstring $(MAKECMDGOALS), clean)), 0)
  -include $(DEPFILES)
endif

libkern:
	$(MAKE) -C libkern libkern.a

cscope:
	cscope -b include/*.h ./*.[cS] 

ctags:
	find -iname '*.[ch]' | ctags --language-force=c -L-
	find -iname '*.S' | ctags -a --language-force=asm -L-
	find $(SYSROOT)/mips-mti-elf/include -type f -iname 'mips*' \
		| ctags -a --language-force=c -L-
	find $(SYSROOT)/lib/gcc/mips-mti-elf/*/include -type f -iname '*.h' \
		| ctags -a --language-force=c -L-

astyle:
	astyle --options=astyle.options --recursive "*.h" "*.c" \
	       --exclude=include/bitset.h --exclude=include/_bitset.h \
	       --exclude=include/hash.h --exclude=include/queue.h \
	       --exclude=include/tree.h --exclude=vm_phys.c

test:
	for file in $(wildcard *.test); do		\
	  echo -n "Running $${file}... ";		\
	  if ./$${file}; then				\
	    echo "\033[32;1mPASSED\033[0m";		\
	  else						\
	    echo "\033[31;1mFAILED\033[0m";		\
	  fi						\
	done

clean:
	$(MAKE) -C libkern clean
	$(RM) -f .*.D *.ko *.o *.a *.lst *~ *.elf *.map *.log
	$(RM) -f tags cscope.out
	$(RM) -f $(TESTS)

.PHONY: ctags cscope libkern astyle
