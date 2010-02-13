## CONFIG

INSTALL_PREFIX = /usr/local

CFLAGS = -Wall -O3 -fPIC -fomit-frame-pointer -I vm -D_GNU_SOURCE
EXTFLAGS = -pthread
MAJOR=0
MINOR=1
MAKESO = $(CC) -shared
LIBNEKO_NAME = libneko.so.${MAJOR}.${MINOR}
LIBNEKO_LIBS = -ldl -lgc -lm
NEKOVM_FLAGS = -Lbin -lneko
STD_NDLL_FLAGS = -lm
INSTALL_FLAGS =

NEKO_EXEC = LD_LIBRARY_PATH=../bin:${LD_LIBRARY_PATH} NEKOPATH=../boot:../bin ../bin/neko

# For 64 bit
#
# CFLAGS += -D_64BITS

# For profiling VM
#
# CFLAGS += -DNEKO_PROF

# For lower memory usage (takes more CPU !)
#
# CFLAGS += -DLOW_MEM

### MAKE

VM_OBJECTS = vm/stats.o vm/main.o
STD_OBJECTS = libs/std/buffer.o libs/std/date.o libs/std/file.o libs/std/init.o libs/std/int32.o libs/std/math.o libs/std/string.o libs/std/random.o libs/std/serialize.o libs/std/socket.o libs/std/sys.o libs/std/xml.o libs/std/module.o libs/std/md5.o libs/std/utf8.o libs/std/memory.o libs/std/misc.o libs/std/thread.o libs/std/process.o
LIBNEKO_OBJECTS = vm/alloc.o vm/builtins.o vm/callback.o vm/interp.o vm/load.o vm/objtable.o vm/others.o vm/hash.o vm/module.o vm/jit_x86.o vm/threads.o

all: createbin libneko neko std compiler libs

createbin:
	-mkdir bin 2>/dev/null

libneko: bin/${LIBNEKO_NAME}

libs:
	(cd src; ${NEKO_EXEC} nekoc tools/install.neko)
	(cd src; ${NEKO_EXEC} tools/install ${INSTALL_FLAGS})

doc:
	(cd src; ${NEKO_EXEC} nekoc tools/makedoc.neko)
	(cd src; ${NEKO_EXEC} tools/makedoc)

test:
	(cd src; ${NEKO_EXEC} nekoc tools/test.neko)
	(cd src; ${NEKO_EXEC} tools/test)

neko: bin/neko

std: bin/std.ndll

compiler:
	(cd src; ${NEKO_EXEC} nekoml -nostd neko/Main.nml nekoml/Main.nml)
	(cd src; ${NEKO_EXEC} nekoc -link ../boot/nekoc.n neko/Main)
	(cd src; ${NEKO_EXEC} nekoc -link ../boot/nekoml.n nekoml/Main)

bin/${LIBNEKO_NAME}: ${LIBNEKO_OBJECTS}
	${MAKESO} -Wl,-soname,libneko.so.${MAJOR} ${EXTFLAGS} -o $@ ${LIBNEKO_OBJECTS} ${LIBNEKO_LIBS}
	ln -s ${LIBNEKO_NAME} bin/libneko.so
	ln -s ${LIBNEKO_NAME} bin/libneko.so.${MAJOR}

bin/neko: $(VM_OBJECTS)
	${CC} ${CFLAGS} -o $@ ${VM_OBJECTS} ${NEKOVM_FLAGS}

bin/std.ndll: ${STD_OBJECTS}
	${MAKESO} ${EXTFLAGS} -o $@ ${STD_OBJECTS} ${STD_NDLL_FLAGS}

clean:
	rm -rf bin/${LIBNEKO_NAME} ${LIBNEKO_OBJECTS} ${VM_OBJECTS}
	rm -rf bin/libneko.so bin/libneko.so.${MAJOR}
	rm -rf bin/nekoml.std
	rm -rf bin/neko bin/nekoc bin/nekoml bin/nekotools
	rm -rf bin/std bin/*.ndll bin/*.n libs/*/*.o
	rm -rf src/*.n src/neko/*.n src/nekoml/*.n src/tools/*.n
	rm -rf bin/mtypes bin/tools

install:
	cp bin/${LIBNEKO_NAME} ${INSTALL_PREFIX}/lib
	cp bin/neko bin/nekoc bin/nekotools bin/nekoml bin/nekoml.std ${INSTALL_PREFIX}/bin
	-mkdir ${INSTALL_PREFIX}/lib/neko
	cp bin/*.ndll ${INSTALL_PREFIX}/lib/neko
	-mkdir ${INSTALL_PREFIX}/include
	cp vm/neko*.h ${INSTALL_PREFIX}/include

uninstall:
	rm -rf ${INSTALL_PREFIX}/lib/${LIBNEKO_NAME}
	rm -rf ${INSTALL_PREFIX}/bin/neko ${INSTALL_PREFIX}/bin/nekoc ${INSTALL_PREFIX}/bin/nekotools
	rm -rf ${INSTALL_PREFIX}/lib/neko

.SUFFIXES : .c .o

.c.o :
	${CC} ${CFLAGS} ${EXTFLAGS} -o $@ -c $<

.PHONY: all libneko libs neko std compiler clean doc test
