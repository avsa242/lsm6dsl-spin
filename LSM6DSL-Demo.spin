{
---------------------------------------------------------------------------------------------------
    Filename:       LSM6DSL-Demo.spin
    Description:    Demo of the LSM6DSL driver
        * 6DoF data output
    Author:         Jesse Burt
    Started:        Feb 19, 2021
    Updated:        Oct 10, 2025
    Copyright (c) 2025 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

' Uncomment these lines to use an SPI-connected sensor (default is I2C)
'#define LSM6DSL_SPI
'#pragma exportdef(LSM6DSL_SPI)

' Uncomment the two lines below to use the driver with a bytecode-based SPI engine
'#define LSM6DSL_SPI_BC
'#pragma exportdef(LSM6DSL_SPI_BC)


CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.imu.6dof.lsm6dsl" | {I2C} SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0, ...
                                        {SPI} CS=0, SCK=1, MOSI=2, MISO=3
    time:   "time"


PUB main() | a[3], g[3]

    setup()
    sensor.preset_active()

    repeat
        repeat
        until sensor.accel_data_rdy()           ' wait for new accel data

        ' copy accelerometer data (micro-g's) to an array here
        sensor.accel_g(@a[sensor.X_AXIS], @a[sensor.Y_AXIS], @a[sensor.Z_AXIS])

        repeat
        until sensor.gyro_data_rdy()             ' wait for new mag data

        ' copy gyroscope data (micro-degrees per second) to an array here
        sensor.gyro_dps(@g[sensor.X_AXIS], @g[sensor.Y_AXIS], @g[sensor.Z_AXIS])

        ser.pos_xy(0, 3)
        show_data(@"Accel  (g):  ", a[sensor.X_AXIS], a[sensor.Y_AXIS], a[sensor.Z_AXIS])
        show_data(@"Gyro (dps):  ", g[sensor.X_AXIS], g[sensor.Y_AXIS], g[sensor.Z_AXIS])

        if ( ser.getchar_noblock() == "c" )     ' press "c" to calibrate/zero the sensors
            cal_accel()
            cal_gyro()


PUB show_data(p_str, x, y, z) | axis, tmp[3], sign

    longmove(@tmp, @x, 3)

    ser.str(p_str)
    repeat axis from 0 to 2
        ' The sign is normally taken from the whole part and just displayed.
        ' Because we're showing values divided by 1_000_000, it won't show negative until the value
        '   reaches -1_000_000 or less, so values like -0_800_000 will display without the '-',
        '   so process the sign display separately here
        if ( tmp[axis] < 0 )
            sign := "-"
        else
            sign := " "
        ser.printf(@"%c%d.%06.6d     ", sign, ...
                                        abs(tmp[axis] / 1_000_000), ...
                                        abs(tmp[axis] // 1_000_000) )
    ser.newline()


PUB cal_accel()
' Calibrate the accelerometer
    ser.pos_xy(0, 3)
    ser.str(@"Calibrating accelerometer...")
    sensor.calibrate_accel()
    ser.pos_xy(0, 3)
    ser.clear_ln()


PUB cal_gyro()
' Calibrate the gyroscope
    ser.pos_xy(0, 4)
    ser.str(@"Calibrating gyroscope...")
    sensor.calibrate_gyro()
    ser.pos_xy(0, 4)
    ser.clear_ln()


PUB setup()

    ser.start()
    time.msleep(20)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"LSM6DSL driver started")
    else
        ser.strln(@"LSM6DSL driver failed to start - halting")
        repeat


DAT
{
Copyright 2025 Jesse Burt

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

