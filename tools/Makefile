CC = gcc
CFLAGS = -O2
LINK = gcc
LFLAGS = -Xlinker -s
LDLIBS = -lm
SRCS = main.c ops.c globals.c exp.c symbols.c mne6303.c mne6502.c mne68705.c mne6811.c
OBJS = $(SRCS:.c=.o)

# Targets

all:	dasm

dasm:	$(OBJS)
	$(LINK) $(LFLAGS) -o $@ $(LDLIBS) $(OBJS)

clean:
	rm -f dasm $(OBJS)

# Dependecies

exp.o: exp.c asm.h
ftohex.o: ftohex.c
globals.o: globals.c asm.h
main.o: main.c asm.h
mne6303.o: mne6303.c asm.h
mne6502.o: mne6502.c asm.h
mne6811.o: mne6811.c asm.h
mne68705.o: mne68705.c asm.h
ops.o: ops.c asm.h
symbols.o: symbols.c asm.h
