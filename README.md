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
* Pedometer (step counter) embedded functionality support

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C engine
* sensor.accel.common.spinh (provided by spin-standard-library)
* sensor.gyroscope.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* sensor.accel.common.spinh (provided by spin-standard-library)
* sensor.gyroscope.common.spinh (provided by spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.1.1-beta)  | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (6.1.1-beta)  | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (6.1.1-beta)  | NuCode      | FTBFS                 |
| P2        | SPIN2    | FlexSpin (6.1.1-beta)  | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* Click detection currently only supports single-click

## Known issues

* When `gyro_scale()` is set to 2000dps, it is possible for the measurements returned by `gyro_dps()` to overflow 32-bit signed integer max - this isn't protected

