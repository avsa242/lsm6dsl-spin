{
    --------------------------------------------
    Filename: core.con.lsm6dsl.spin
    Author:
    Description:
    Copyright (c) 2021
    Started Feb 18, 2021
    Updated Feb 18, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    SPI_MAX_FREQ    = 10_000_000                ' device max SPI bus freq
    SPI_MODE        = 0                         ' 0 or 3
    T_POR           = 100                         ' startup time (usecs)

    DEVID_RESP      = $6A                       ' device ID expected response

    READ            = 1 << 7                    ' R/W bit: read

' Register definitions
    WHO_AM_I        = $0F

PUB Null{}
' This is not a top-level object

