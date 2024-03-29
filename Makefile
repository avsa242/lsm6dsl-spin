# lsm6dsl-spin Makefile - requires GNU Make, or compatible
# Variables below can be overridden on the command line
#	e.g. make IFACE=LSM6DSL_SPI LSM6DSL-Demo.spin

# P1, P2 device nodes and baudrates
#P1DEV=
P1BAUD=115200
#P2DEV=
P2BAUD=2000000

# P1, P2 compilers
#P1BUILD=openspin
P1BUILD=flexspin --interp=rom
P2BUILD=flexspin -2

# LSM6DSL interface: I2C, SPI
IFACE=LSM6DSL_I2C
#IFACE=LSM6DSL_SPI

# Paths to spin-standard-library, and p2-spin-standard-library,
#  if not specified externally
SPIN1_LIB_PATH=-L ../spin-standard-library/library
SPIN2_LIB_PATH=-L ../p2-spin-standard-library/library


# -- Internal --
SPIN1_DRIVER_FN=sensor.imu.6dof.lsm6dsl.spin
SPIN2_DRIVER_FN=sensor.imu.6dof.lsm6dsl.spin2
CORE_FN=core.con.lsm6dsl.spin
# --

# Build all targets (build only)
all: LSM6DSL-Demo.binary LSM6DSL-Demo.bin2 LSM6DSL-ClickDemo.binary LSM6DSL-ClickDemo.bin2

# Load P1 or P2 target (will build first, if necessary)
p1demo: loadp1demo
p1click: loadp1click
p2demo: loadp2demo
p2click: loadp2click

# Build binaries
LSM6DSL-AutoSleepDemo.binary: LSM6DSL-AutoSleepDemo.spin $(SPIN1_DRIVER_FN) $(CORE_FN)
	$(P1BUILD) $(SPIN1_LIB_PATH) -b -D $(IFACE) LSM6DSL-AutoSleepDemo.spin

LSM6DSL-AutoSleepDemo.bin2: LSM6DSL-AutoSleepDemo.spin2 $(SPIN2_DRIVER_FN) $(CORE_FN)
	$(P2BUILD) $(SPIN2_LIB_PATH) -b -D $(IFACE) -o LSM6DSL-AutoSleepDemo.bin2 LSM6DSL-AutoSleepDemo.spin2

LSM6DSL-Demo.binary: LSM6DSL-Demo.spin $(SPIN1_DRIVER_FN) $(CORE_FN)
	$(P1BUILD) $(SPIN1_LIB_PATH) -b -D $(IFACE) LSM6DSL-Demo.spin

LSM6DSL-Demo.bin2: LSM6DSL-Demo.spin2 $(SPIN2_DRIVER_FN) $(CORE_FN)
	$(P2BUILD) $(SPIN2_LIB_PATH) -b -D $(IFACE) -o LSM6DSL-Demo.bin2 LSM6DSL-Demo.spin2

LSM6DSL-ClickDemo.binary: LSM6DSL-ClickDemo.spin $(SPIN1_DRIVER_FN) $(CORE_FN)
	$(P1BUILD) $(SPIN1_LIB_PATH) -b -D $(IFACE) LSM6DSL-ClickDemo.spin

LSM6DSL-ClickDemo.bin2: LSM6DSL-ClickDemo.spin2 $(SPIN2_DRIVER_FN) $(CORE_FN)
	$(P2BUILD) $(SPIN2_LIB_PATH) -b -D $(IFACE) -o LSM6DSL-ClickDemo.bin2 LSM6DSL-ClickDemo.spin2

LSM6DSL-FreeFallDemo.binary: LSM6DSL-FreeFallDemo.spin $(SPIN1_DRIVER_FN) $(CORE_FN)
	$(P1BUILD) $(SPIN1_LIB_PATH) -b -D $(IFACE) LSM6DSL-FreeFallDemo.spin

LSM6DSL-FreeFallDemo.bin2: LSM6DSL-FreeFallDemo.spin2 $(SPIN2_DRIVER_FN) $(CORE_FN)
	$(P2BUILD) $(SPIN2_LIB_PATH) -b -D $(IFACE) -o LSM6DSL-FreeFallDemo.bin2 LSM6DSL-FreeFallDemo.spin2

# Load binaries to RAM (will build first, if necessary)
loadp1demo: LSM6DSL-Demo.binary
	proploader -t -p $(P1DEV) -Dbaudrate=$(P1BAUD) LSM6DSL-Demo.binary

loadp1click: LSM6DSL-ClickDemo.binary
	proploader -t -p $(P1DEV) -Dbaudrate=$(P1BAUD) LSM6DSL-ClickDemo.binary

loadp1ffall: LSM6DSL-FreeFallDemo.binary
	proploader -t -p $(P1DEV) -Dbaudrate=$(P1BAUD) LSM6DSL-FreeFallDemo.binary

loadp1autoslp: LSM6DSL-AutoSleepDemo.binary
	proploader -t -p $(P1DEV) -Dbaudrate=$(P1BAUD) LSM6DSL-AutoSleepDemo.binary

loadp2demo: LSM6DSL-Demo.bin2
	loadp2 -SINGLE -p $(P2DEV) -v -b$(P2BAUD) -l$(P2BAUD) LSM6DSL-Demo.bin2 -t

loadp2click: LSM6DSL-ClickDemo.bin2
	loadp2 -SINGLE -p $(P2DEV) -v -b$(P2BAUD) -l$(P2BAUD) LSM6DSL-ClickDemo.bin2 -t

loadp2ffall: LSM6DSL-FreeFallDemo.bin2
	loadp2 -SINGLE -p $(P2DEV) -v -b$(P2BAUD) -l$(P2BAUD) LSM6DSL-FreeFallDemo.bin2 -t

loadp2autoslp: LSM6DSL-AutoSleepDemo.bin2
	loadp2 -SINGLE -p $(P2DEV) -v -b$(P2BAUD) -l$(P2BAUD) LSM6DSL-AutoSleepDemo.bin2 -t

# Remove built binaries and assembler outputs
clean:
	rm -fv *.binary *.bin2 *.pasm *.p2asm

