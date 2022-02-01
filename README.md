# lsm6dsl-spin

--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the ST LSM6DSL 6DoF IMU.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at 4MHz (P1), up to 10MHz (P2)
* Set accelerometer and gyroscope full-scale, data rate
* Read accelerometer raw data, or scaled to micro-G's (live or from FIFO)
* Read gyroscope raw data, or scaled to micro-dps (live or from FIFO)
* Data ready flags
* Manually or automatically set accel/gyro bias offsets (accel: on-chip, gyro: in MCU RAM)
* Soft-reset
* Gyroscope sleep mode
* Set gyroscope low-pass filter
* Set INT1 interrupt mask
* Click/tap-detection (single): set threshold, time, latency, per-axis detection
* Free-fall detection: set threshold, time
* Auto-sleep/wake/(in)activity detection
* FIFO functionality: empty, full, overrun, watermark flags, unread sample count, set decimation of data entries to FIFO, set mode, set data rate, set watermark level

## Requirements

P1/SPIN1:

* spin-standard-library
* 1 extra core/cog for the PASM SPI engine

P2/SPIN2:

* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1 OpenSpin (bytecode): Untested (deprecated)
* P1/SPIN1 FlexSpin (bytecode): OK, tested with 5.9.7-beta
* P1/SPIN1 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~P2/SPIN2 FlexSpin (nu-code): FTBFS, tested with 5.9.7-beta~~
* P2/SPIN2 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Click detection currently only supports single-click

## Known issues

* When `GyroScale()` is set to 2000dps, it is possible for the measurements returned by `GyroDPS()` to overflow 32-bit signed integer max - this isn't protected

