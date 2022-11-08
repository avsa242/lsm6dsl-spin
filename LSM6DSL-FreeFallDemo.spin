{
    --------------------------------------------
    Filename: LSM6DSL-FreeFall-Demo.spin
    Author: Jesse Burt
    Description: Demo of the LSM6DSL driver
        Free-fall detection functionality
    Copyright (c) 2022
    Started Sep 6, 2021
    Updated Nov 8, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
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

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    imu     : "sensor.imu.6dof.lsm6dsl"

PUB main{}

    setup{}
    imu.preset_freefall{}                       ' default settings, but enable
                                                ' sensors, set scale factors,
                                                ' and free-fall parameters
    ser.pos_xy(0, 3)
    ser.str(string("Sensor stable       "))
    repeat
        ser.pos_xy(0, 3)
        ' check if sensor detects free-fall condition
        ' Note that InFreeFall() reads the WAKE_UP_SRC register, which also
        '   clears the interrupt. This is necessary when routing the free-fall
        '   interrupt to one of the sensor's INT pins, if interrupts are being
        '   latched
        if (imu.in_freefall{})
            ser.strln(string("Sensor in free-fall!"))
            ser.str(string("Press any key to reset"))
            ser.getchar{}                       ' wait for keypress
            ser.pos_x(0)
            ser.clear_line{}
            ser.pos_xy(0, 3)
            ser.str(string("Sensor stable       "))
        if (ser.rxcheck{} == "c")               ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets

PUB calibrate{}

    ser.pos_xy(0, 7)
    ser.str(string("Calibrating..."))
    imu.calibrate_accel{}
    imu.calibrate_gyro{}
    ser.pos_x(0)
    ser.clear_line{}

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
#ifdef LSM6DSL_SPI
    if imu.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.strln(string("LSM6DSL driver started (SPI)"))
#else
    if imu.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS)
        ser.strln(string("LSM6DSL driver started (I2C)"))
#endif
    else
        ser.strln(string("LSM6DSL driver failed to start - halting"))
        repeat

DAT
{
Copyright 2022 Jesse Burt

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
