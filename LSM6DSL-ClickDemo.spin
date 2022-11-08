{
    --------------------------------------------
    Filename: LSM6DSL-ClickDemo.spin
    Author: Jesse Burt
    Description: Demo of the LSM6DSL driver
        click-detection functionality
    Copyright (c) 2022
    Started Mar 7, 2021
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

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    imu     : "sensor.imu.6dof.lsm6dsl"

PUB main{} | click_src, int_act, dclicked, sclicked, z_clicked, y_clicked, x_clicked

    setup{}
    imu.preset_click_det{}                      ' preset settings for
                                                ' click-detection

    ser.hide_cursor{}                           ' hide terminal cursor

    repeat until (ser.rx_check{} == "q")        ' press q to quit
        click_src := imu.clicked_int{}
        int_act := ((click_src >> 6) & 1)
        dclicked := ((click_src >> 4) & 1)
        sclicked := ((click_src >> 5) & 1)
        z_clicked := ((click_src >> 0) & 1)
        y_clicked := ((click_src >> 1) & 1)
        x_clicked := (click_src & 2)
        ser.pos_xy(0, 3)
        ser.printf1(string("Click interrupt: %s (%d)\n"), yesno(int_act))
        ser.printf1(string("Double-clicked:  %s (%d)\n"), yesno(dclicked))
        ser.printf1(string("Single-clicked:  %s (%d)\n"), yesno(sclicked))
        ser.printf1(string("Z-axis clicked:  %s\n"), yesno(z_clicked))
        ser.printf1(string("Y-axis clicked:  %s\n"), yesno(y_clicked))
        ser.printf1(string("X-axis clicked:  %s\n"), yesno(x_clicked))

    ser.show_cursor{}                            ' restore terminal cursor
    repeat

PRI yesno(val): resp
' Return pointer to string "Yes" or "No" depending on value called with
    case val
        0:
            return string("No ")
        1:
            return string("Yes")

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
