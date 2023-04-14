{
    --------------------------------------------
    Filename: LSM6DSL-StepCountDemo.spin
    Author: Jesse Burt
    Description: LSM6DSL driver demo
        * Pedometer step count output
    Copyright (c) 2023
    Started Apr 14, 2023
    Updated Apr 14, 2023
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DLSM6DSL_SPI
        -DLSM6DSL_SPI_BC
        -DLSM6DSL_I2C (default if none specified)
        -DLSM6DSL_I2C_BC
}
CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    ADDR_BITS   = 0                             ' 0, 1

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1
    MOSI_PIN    = 2
    MISO_PIN    = 3
' --

OBJ

    cfg:    "boardcfg.flip"
    sensor: "sensor.imu.6dof.lsm6dsl"
    ser:    "com.serial.terminal.ansi"
    time:   "time"

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(20)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef LSM6DSL_SPI
    if (sensor.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
#else
    if (sensor.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS))
#endif
        ser.strln(string("LSM6DSL driver started"))
    else
        ser.strln(string("LSM6DSL driver failed to start - halting"))
        repeat

    sensor.preset_pedometer{}

    repeat
        ser.pos_xy(0, 3)
        ser.printf1(@"Step count: %5.5d", sensor.step_count())
        case ser.rx_check{}
            "c":
                sensor.calibrate_accel{}
                sensor.calibrate_gyro{}
            "r":
                sensor.step_reset{}

DAT
{
Copyright 2023 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

