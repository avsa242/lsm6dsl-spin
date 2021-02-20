{
    --------------------------------------------
    Filename: sensor.imu.6dof.lsm6dsl.spi.spin
    Author: Jesse Burt
    Description: Driver for the ST LSM6DSL 6DoF IMU
    Copyright (c) 2021
    Started Feb 18, 2021
    Updated Feb 19, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF               = 3
    GYRO_DOF                = 3
    MAG_DOF                 = 0
    BARO_DOF                = 0
    DOF                     = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

' Constants used in low-level SPI read/write
    READ                    = 1 << 7
    WRITE                   = 0

' Bias adjustment (AccelBias(), GyroBias(), MagBias()) read or write
    R                       = 0
    W                       = 1

' Axis-specific constants
    X_AXIS                  = 0
    Y_AXIS                  = 1
    Z_AXIS                  = 2
    ALL_AXIS                = 3

' Temperature scale constants
    C                       = 0
    F                       = 1

VAR

    long _ares, _gres
    long _gbiasraw[GYRO_DOF]

OBJ

' choose an SPI engine below
    spi : "com.spi.bitbang"                     ' PASM SPI engine (~4MHz)
    core: "core.con.lsm6dsl"                    ' hw-specific low-level const's
    time: "time"                                ' Basic timing functions

PUB Null{}
' This is not a top-level object

PUB Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status
' Start using custom IO pins
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if (status := spi.init(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, 0))
            time.usleep(core#T_POR)             ' wait for device startup
            if deviceid{} == core#DEVID_RESP    ' validate device
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    spi.deinit{}

PUB Defaults{}
' Set factory defaults
    reset{}

PUB Preset_IMUActive{}
' Like Defaults(), but sets:
'   * Sensor powered up/actively measuring
'   * Accelerometer: 2g, 52Hz
'   * Gyroscope: 250dps, 52Hz
    acceldatarate(52)
    accelscale(2)
    gyrodatarate(52)
    gyroscale(250)

PUB AccelADCRes(adc_res): curr_res
' dummy method

PUB AccelAxisEnabled(xyz_mask): curr_mask
' dummy method

PUB AccelBias(bias_x, bias_y, bias_z, rw) | tmp
' Read or write/manually set accelerometer calibration offset values (on-chip)
'   Valid values: (bias_x, bias_y, bias_z)
'       When rw == R (0): pointers to variables containing offsets
'       When rw == W (1): -127..127
'   Any other value for rw or bias_ parameters is ignored
    case rw
        R:
            tmp := 0
            readreg(core#X_OFS_USR, 3, @tmp)
            ' extend sign and copy to pointees
            long[bias_x] := ~tmp.byte[X_AXIS]
            long[bias_y] := ~tmp.byte[Y_AXIS]
            long[bias_z] := ~tmp.byte[Z_AXIS]
            return
        W:
            case bias_x
                -127..127:
                    writereg(core#X_OFS_USR, 1, @bias_x)
                other:
                    return
            case bias_y
                -127..127:
                    writereg(core#Y_OFS_USR, 1, @bias_y)
                other:
                    return
            case bias_z
                -127..127:
                    writereg(core#Z_OFS_USR, 1, @bias_z)
                other:
                    return
        other:
            return

PUB AccelClearInt{}
' Clear Accelerometer interrupts

PUB AccelData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read the Accelerometer output registers
    readreg(core#OUTX_L_XL, 6, @tmp)
    long[ptr_x] := ~~tmp.word[X_AXIS]
    long[ptr_y] := ~~tmp.word[Y_AXIS]
    long[ptr_z] := ~~tmp.word[Z_AXIS]

PUB AccelDataOverrun{}: flag
' Flag indicating previously acquired data has been overwritten

PUB AccelDataRate(rate): curr_rate
' Set accelerometer output data rate, in Hz
'   Valid values:
'       Low power mode: 0, 1 (1.6), 12 (12.5), 26, 52
'       Normal mode: 104, 208
'       High-perf mode: 416, 833, 1660, 3330, 6660
'   Any other value polls the chip and returns the current setting
    readreg(core#CTRL1_XL, 1, @curr_rate)
    case rate
        0, 1, 12, 26, 52, 104, 208, 416, 833, 1660, 3330, 6660:
            rate := lookdownz(rate: 0, 12, 26, 52, 104, 208, 416, 833, 1660, {
}           3330, 6660, 1) << core#ODR_XL
        other:
            curr_rate >>= core#ODR_XL
            return lookupz(curr_rate: 0, 12, 26, 52, 104, 208, 416, 833, 1660,{
}           3330, 6660, 1)

    rate := ((curr_rate & core#ODR_XL_MASK) | rate)
    writereg(core#CTRL1_XL, 1, @rate)

PUB AccelDataReady{}: flag
' Flag indicating new accelerometer data available
'   Returns: TRUE (-1) if new data available, FALSE (0) otherwise
    readreg(core#STATUS, 1, @flag)
    return ((flag & core#XLRDY) == core#XLRDY)

PUB AccelG(ptr_x, ptr_y, ptr_z) | tmp[ACCEL_DOF]
' Read the Accelerometer data and scale the outputs to
'   micro-g's (1_000_000 = 1.000000 g = 9.8 m/s/s)
    acceldata(@tmp[X_AXIS], @tmp[Y_AXIS], @tmp[Z_AXIS])
    long[ptr_x] := tmp[X_AXIS] * _ares
    long[ptr_y] := tmp[Y_AXIS] * _ares
    long[ptr_z] := tmp[Z_AXIS] * _ares

PUB AccelInt{}: flag
' Flag indicating accelerometer interrupt asserted

PUB AccelLowPassFilter(freq): curr_freq
' Enable accelerometer data low-pass filter

PUB AccelOpMode(mode): curr_mode
' Set accelerometer operating mode

PUB AccelScale(scale): curr_scl
' Set the full-scale range of the accelerometer, in g's
    readreg(core#CTRL1_XL, 1, @curr_scl)
    case scale
        2, 4, 8, 16:
            scale := lookdownz(scale: 2, 16, 4, 8)
            _ares := lookupz(scale: 0_061, 0_122, 0_244, 0_488)
            scale <<= core#FS_XL
        other:
            curr_scl := ((curr_scl >> core#FS_XL) & core#FS_XL_BITS)
            return lookupz(curr_scl: 2, 16, 4, 8)
    scale := ((curr_scl & core#FS_XL_MASK) | scale)
    writereg(core#CTRL1_XL, 1, @scale)

PUB CalibrateAccel{} | acceltmp[ACCEL_DOF], axis, x, y, z, samples, scale_orig, drate_orig, fifo_orig, scl
' Calibrate the accelerometer

PUB CalibrateGyro{} | gyrotmp[GYRO_DOF], axis, x, y, z, samples, scale_orig, drate_orig, fifo_orig, scl
' Calibrate the accelerometer

PUB CalibrateMag{} | magtmp[MAG_DOF], axis, x, y, z, samples, scale_orig, drate_orig, fifo_orig, scl
' Calibrate the magnetometer

PUB CalibrateXLG{}
' Dummy method

PUB ClickAxisEnabled(mask): curr_mask
' Enable click detection per axis, and per click type

PUB Clicked{}: flag
' Flag indicating the sensor was single or double

PUB ClickedInt{}: intstat
' Clicked interrupt status

PUB ClickIntEnabled(state): curr_state
' Enable click interrupts on INT1

PUB ClickLatency(clat): curr_clat
' Set maximum elapsed interval between start of click and end of click, in uSec

PUB ClickThresh(level): curr_lvl
' Set threshold for recognizing a click, in micro

PUB ClickTime(usec): curr_ctime
' Set maximum elapsed interval between start of click and end of click, in uSec

PUB ClockSource(src): curr_src
' Set sensor clock source

PUB DeviceID{}: id
' Read device identification
    readreg(core#WHO_AM_I, 1, @id)

PUB DoubleClickWindow(dctime): curr_dctime
' Set maximum elapsed interval between two consecutive clicks, in uSec

PUB FIFOEmpty{}: flag
' Flag indicating FIFO is empty

PUB FIFOEnabled(state): curr_state
' Enable FIFO memory

PUB FIFOFull{}: flag
' Flag indicating FIFO full/overflowed

PUB FIFOMode(mode): curr_mode
' Set FIFO mode

PUB FIFORead(nr_bytes, ptr_data)
' Read FIFO data

PUB FIFOReset{}
' Reset the FIFO

PUB FIFOSource(mask): curr_mask
' Set FIFO source data, as a bitmask

PUB FIFOThresh(level): curr_lvl
' Set FIFO watermark/threshold level

PUB FIFOUnreadSamples{}: nr_samples
' Number of unread samples stored in FIFO

PUB GyroAxisEnabled(mask): curr_mask
' Enable data output for gyroscope (all axes)

PUB GyroBias(bias_x, bias_y, bias_z, rw)
' Read or write/manually set gyroscope calibration offset values
'   Valid values: (bias_x, bias_y, bias_z)
'       When rw == R (0): pointers to variables containing offsets
'       When rw == W (1): -32768..32767
'   Any other value for rw or bias_ parameters is ignored
    case rw
        R:
            longmove(bias_x, @_gbiasraw, GYRO_DOF)
            return
        W:
            case bias_x
                -32768..32767:
                other:
                    return
            case bias_y
                -32768..32767:
                other:
                    return
            case bias_z
                -32768..32767:
                other:
                    return
            longmove(@_gbiasraw, bias_x, GYRO_DOF)
        other:
            return

PUB GyroClearInt{}
' Clears out any interrupts set up on the Gyroscope and resets all Gyroscope interrupt registers to their default values.

PUB GyroData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Reads the Gyroscope output registers
    readreg(core#OUTX_L_G, 6, @tmp)
    long[ptr_x] := ~~tmp.word[X_AXIS] + _gbiasraw[X_AXIS]
    long[ptr_y] := ~~tmp.word[Y_AXIS] + _gbiasraw[Y_AXIS]
    long[ptr_z] := ~~tmp.word[Z_AXIS] + _gbiasraw[Z_AXIS]

PUB GyroDataOverrun{}: flag
' Dummy method

PUB GyroDataRate(rate): curr_rate
' Set gyroscope output data rate, in Hz
'   Valid values:
'       Low power mode: 0, 12 (12.5), 26, 52
'       Normal: 104, 208
'       High-perf mode: 416, 833, 1660, 3330, 6660
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(core#CTRL2_G, 1, @curr_rate)
    case rate
        0, 12, 26, 52, 104, 208, 416, 833, 1660, 3330, 6660:
            rate := lookdownz(rate: 0, 12, 26, 52, 104, 208, 416, 833, 1660, {
}           3330, 6660) << core#ODR_G
        other:
            curr_rate := (curr_rate >> core#ODR_G) & core#ODR_G_BITS
            return lookupz(curr_rate: 0, 12, 26, 52, 104, 208, 416, 833, {
}           1660, 3330, 6660)

    rate := ((curr_rate & core#ODR_G_MASK) | rate)
    writereg(core#CTRL2_G, 1, @rate)

PUB GyroDataReady{}: flag
' Flag indicating new gyroscope data available
'   Returns: TRUE (-1) if new data available, FALSE (0) otherwise
    readreg(core#STATUS, 1, @flag)
    return ((flag & core#GRDY) == core#GRDY)

PUB GyroDPS(ptr_x, ptr_y, ptr_z) | tmp[GYRO_DOF]
' Read the Gyroscope output registers and scale the outputs to micro
    gyrodata(@tmp[X_AXIS], @tmp[Y_AXIS], @tmp[Z_AXIS])
    long[ptr_x] := tmp[X_AXIS] * _gres
    long[ptr_y] := tmp[Y_AXIS] * _gres
    long[ptr_z] := tmp[Z_AXIS] * _gres

PUB GyroHighPass(freq): curr_freq
' Set Gyroscope high

PUB GyroInactiveDur(duration): curr_dur
' Set gyroscope inactivity timer (use GyroInactiveSleep to define behavior on inactivity)

PUB GyroInactiveThr(thresh): curr_thr
' Set gyroscope inactivity threshold (use GyroInactiveSleep to define behavior on inactivity)

PUB GyroInactiveSleep(state): curr_state
' Enable gyroscope sleep mode when inactive (see GyroActivityThr)

PUB GyroInt{}: flag
' Flag indicating gyroscope interrupt asserted

PUB GyroIntSelect(mode): curr_mode
' Set gyroscope interrupt generator selection

PUB GyroLowPassFilter(freq): curr_freq
' Set gyroscope output data low

PUB GyroLowPower(state): curr_state
' Enable low

PUB GyroScale(scale): curr_scl
' Set gyroscope full-scale range, in degrees per second
'   Valid values: 125, 250, 500, 1000, 2000
'   Any other value polls the chip and returns the current setting
    curr_scl := 0
    readreg(core#CTRL2_G, 1, @curr_scl)
    case scale
        125, 250, 500, 1000, 2000:
            ' 125dps scale is a separate reg field from the other scales,
            ' but treat it as combined, for simplicity
            scale := lookdownz(scale: 250, 125, 500, 0, 1000, 0, 2000)
            _gres := lookupz(scale: 8_75, 4_375, 17_50, 0, 35_00, 0, 70_00)
            scale <<= core#FS_G
        other:
            curr_scl := (curr_scl >> core#FS_G) & core#FS_G_BITS
            return lookupz(curr_scl: 250, 125, 500, 0, 1000, 0, 2000)

    scale := ((curr_scl & core#FS_G_MASK) | scale)
    writereg(core#CTRL2_G, 1, @scale)

PUB IntActiveState(state): curr_state
' Set interrupt pin active state/logic level

PUB IntClear(mask)
' Clear interrupts, per clear_mask

PUB IntClearedBy(mode): curr_mode
' Select method by which interrupt status may be cleared

PUB Interrupt{}: src
' Indicate interrupt state

PUB IntInactivity{}: flag
' Flag indicating inactivity interrupt asserted

PUB IntLatchEnabled(state): curr_state
' Latch interrupt pin when interrupt asserted

PUB IntMask(mask): curr_mask
' Set interrupt mask

PUB IntOutputType(mode): curr_mode
' Set interrupt pin output type

PUB IntThresh(thresh): curr_thr
' Set interrupt threshold

PUB MagADCRes(adc_res): curr_res
' Set magnetometer ADC resolution, in bits

PUB MagBias(bias_x, bias_y, bias_z, rw) | tmp[2]
' Read or write/manually set magnetometer calibration offset values

PUB MagClearInt{}
' Clear out any interrupts set up on the Magnetometer and

PUB MagData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read the Magnetometer output registers

PUB MagDataOverSampling(ratio): curr_osr
' Set oversampling ratio for magnetometer output data

PUB MagDataOverrun{}: flag
' Flag indicating magnetometer data has overrun

PUB MagDataRate(rate): curr_rate
' Set Magnetometer Output Data Rate, in Hz

PUB MagDataReady{}: flag
' Flag indicating new magnetometer data available

PUB MagFastRead(state): curr_state
' Enable reading of only the MSB of data to increase reading efficiency, at the cost of precision and accuracy

PUB MagGauss(ptr_x, ptr_y, ptr_z) | tmp[MAG_DOF]
' Magnetometer data scaled to micro

PUB MagInt{}: src
' Magnetometer interrupt source(s)

PUB MagIntLevel(state): curr_state
' Set active state of INT_MAG pin when magnetometer interrupt asserted

PUB MagIntsEnabled(state): curr_state
' Enable magnetometer data threshold interrupt

PUB MagIntsLatched(state): curr_state
' Latch interrupts asserted by the magnetometer

PUB MagIntThresh(level): curr_thr
' Set magnetometer interrupt threshold

PUB MagIntThreshX(thresh): curr_thr
' Set magnetometer interrupt threshold, X

PUB MagIntThreshY(thresh): curr_thr
' Set magnetometer interrupt threshold, Y

PUB MagIntThreshZ(thresh): curr_thr
' Set magnetometer interrupt threshold, Z

PUB MagLowPower(state): curr_state
' Enable magnetometer low

PUB MagOpMode(mode): curr_mode
' Set magnetometer operating mode

PUB MagOverflow{}: flag
' Flag indicating magnetometer measurement has overflowed the set range

PUB MagPerf(mode): curr_mode
' Set magnetometer performance mode

PUB MagScale(scale): curr_scl
' Set magnetometer full-scale range, in Gauss

PUB MagSelfTest(state): curr_state
' Enable magnetometer on-chip self-test

PUB MagSoftreset{}
' Perform soft-reset

PUB MagTesla(ptr_x, ptr_y, ptr_z) | tmp[2]
' Magnetometer data scaled to micro-Teslas

PUB MagThreshDebounce(nr_samples)
' Set number of debounce samples required before magnetometer threshold

PUB MagThreshInt{}
' Magnetometer threshold

PUB MagThreshIntMask(mask): curr_mask
' Set magnetometer threshold interrupt mask

PUB MagThreshIntsEnabled(state)
' Enable magnetometer threshold interrupts

PUB MeasureMag{}
' Perform magnetometer measurement

PUB OpMode(mode): curr_mode
' Set operating mode

PUB Powered(state): curr_state
' Enable device power

PUB ReadMagAdj{}
' Read magnetometer factory sensitivity adjustment values

PUB Reset{}
' Reset the device

PUB Temperature{}: temp
' Read chip temperature

PUB TempDataRate(rate): curr_rate
' Set temperature output data rate, in Hz

PUB TempDataReady{}: flag
' Flag indicating new temperature sensor data available

PUB TempScale(scale): curr_scl
' Set temperature scale used by Temperature method

PUB XLGDataReady{}: flag
' Flag indicating new gyroscope/accelerometer data is ready to be read

PUB TempOffset(offs): curr_offs
' Set room temperature offset for Temperature{}

PUB XLGDataRate(rate): curr_rate
' Set output data rate, in Hz, of accelerometer and gyroscope

PUB XLGSoftReset{}
' Perform soft-reset

PRI readReg(reg_nr, nr_bytes, ptr_buff)
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#OUT_TEMP_L..core#OUTZ_H_XL, core#OUT_MAG_RAW_X_L:

        core#FUNC_CFG_ACCESS, core#SENS_SYNC_TIMEFR..core#DRDY_PULSE_CFG_G, {
}       core#INT1_CTRL..core#STATUS, core#SENSHUB1..core#TIMESTAMP2, {
}       core#STP_TIMESTMP_L..core#WRIST_TILT_IA, {
}       core#TAP_CFG..core#SENS_SYNC_SPI_ERR, core#X_OFS_USR..core#Z_OFS_USR:
        other:                                  ' invalid reg_nr
            return

    spi.deselectafter(false)
    spi.wr_byte(reg_nr | core#READ)

    ' read LSByte to MSByte
    spi.deselectafter(true)
    spi.rdblock_lsbf(ptr_buff, nr_bytes)

PRI writeReg(reg_nr, nr_bytes, ptr_buff)
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        core#FUNC_CFG_ACCESS, core#SENS_SYNC_TIMEFR..core#DRDY_PULSE_CFG_G, {
}       core#INT1_CTRL, core#INT2_CTRL, core#CTRL1_XL..core#MASTER_CFG, {
}       core#TIMESTAMP2, core#TAP_CFG..core#SENS_SYNC_SPI_ERR, {
}       core#X_OFS_USR..core#Z_OFS_USR:
        other:
            return

    spi.deselectafter(false)
    spi.wr_byte(reg_nr)

    ' write LSByte to MSByte
    spi.deselectafter(true)
    spi.wrblock_lsbf(ptr_buff, nr_bytes)

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
