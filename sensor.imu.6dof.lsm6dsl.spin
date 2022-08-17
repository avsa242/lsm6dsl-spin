{
    --------------------------------------------
    Filename: sensor.imu.6dof.lsm6dsl.spin
    Author: Jesse Burt
    Description: Driver for the ST LSM6DSL 6DoF IMU
    Copyright (c) 2022
    Started Feb 18, 2021
    Updated Jul 13, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#include "sensor.imu.common.spinh"

CON

' Constants used for I2C mode only
    SLAVE_WR                = core#SLAVE_ADDR
    SLAVE_RD                = core#SLAVE_ADDR|1

    DEF_SCL                 = 28
    DEF_SDA                 = 29
    DEF_HZ                  = 100_000
    I2C_MAX_FREQ            = core#I2C_MAX_FREQ

' FIFO specifications
    FIFO_SIZE               = 4096              ' bytes
    FIFO_UNIT               = 2                 ' 1: bytes, 2: words, 4: longs
    FIFO_SAMPLES_MAX        = (FIFO_SIZE / FIFO_UNIT)-1

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF               = 3
    GYRO_DOF                = 3
    MAG_DOF                 = 0
    BARO_DOF                = 0
    DOF                     = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

' Scales and data rates used during calibration/bias/offset process
    CAL_XL_SCL              = 2
    CAL_G_SCL               = 125
    CAL_M_SCL               = 0
    CAL_XL_DR               = 104
    CAL_G_DR                = 104
    CAL_M_DR                = 0

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

' Gyroscope operating modes
    NORM                    = 0
    SLEEP                   = 1

' Accel/Gyro sleep power modes
    NORMAL                  = 0
    LOPWR                   = 1
    LOPWR_GSLEEP            = 2
    LOPWR_GPWROFF           = 3

' Accelerometer operating modes
    XL_HIPERF               = 0
    XL_NORM                 = 1

' INT1 interrupts
    INACTIVE                = 1 << 7
    SNGTAP                  = 1 << 6
    WAKEUP                  = 1 << 5
    FREEFALL                = 1 << 4
    DBLTAP                  = 1 << 3
    SIXD                    = 1 << 2
    TILT                    = 1 << 1
    TMR_END                 = 1

' FIFO operating modes
    OFF                     = %000
    FIFO                    = %001
    CONT_TRIG               = %011
    OFF_TRIG                = %100
    CONT                    = %110

' Output data source
    GYRO_LIVE               = 0
    GYRO_FIFO               = 1
    ACCEL_LIVE              = 0
    ACCEL_FIFO              = 1

VAR

    long _CS
    byte _adata_src, _gdata_src

OBJ

{ SPI? }
#ifdef LSM6DSL_SPI
{ decide: Bytecode SPI engine, or PASM? Default is PASM if BC isn't specified }
#ifdef LSM6DSL_SPI_BC
    spi : "com.spi.nocog"                       ' BC SPI engine
#else
    spi : "com.spi.bitbang-nocs"                ' PASM SPI engine
#endif
#else
{ no, not SPI - default to I2C }
#define LSM6DSL_I2C
{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef LSM6DSL_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif

#endif
    core: "core.con.lsm6dsl"                    ' hw-specific low-level const's
    time: "time"                                ' Basic timing functions

PUB Null{}
' This is not a top-level object

#ifdef LSM6DSL_I2C
PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom IO pins
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            if deviceid{} == core#DEVID_RESP    ' validate device
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#elseifdef LSM6DSL_SPI
PUB Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status
' Start using custom IO pins
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if (status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE))
            time.usleep(core#T_POR)             ' wait for device startup
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            if deviceid{} == core#DEVID_RESP    ' validate device
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#endif

PUB Stop{}

#ifdef LSM6DSL_I2C
    i2c.deinit{}
#elseifdef LSM6DSL_SPI
    spi.deinit{}
#endif

PUB Defaults{}
' Set factory defaults
    reset{}

PUB Preset_FreeFall{}
' Like Defaults(), but sets:
'   * Sensor powered up/actively measuring
'   * Accelerometer: 2g, 416Hz
'   * Gyroscope: 250dps, 52Hz
'   * Free-fall duration: 6 samples
'   * Free-fall threshold: 312mg
    reset{}
    blockdataupdate{}
    acceldatarate(416)
    accelscale(2)
    gyrodatarate(52)
    gyroscale(250)
    freefalltime(6)
    freefallthresh(312)
    clickintenabled(TRUE)

PUB Preset_Active{}
' Like Defaults(), but sets:
'   * Sensor powered up/actively measuring
'   * Accelerometer: 2g, 52Hz
'   * Gyroscope: 250dps, 52Hz
    reset{}
    blockdataupdate{}
    acceldatarate(52)
    accelscale(2)
    gyrodatarate(52)
    gyroscale(250)

PUB Preset_ClickDet{}
' Presets for click-detection
    reset{}
    accelscale(2)
    acceldatarate(416)
    clickthresh(0_125000)
    clickaxisenabled(%111)
    clicktime(38)
    clicklatency(9)
    clickintenabled(TRUE)
    int1mask(SNGTAP)

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

PUB AccelBiasRes(abiasres): curr_res
' Set resolution of accelerometer bias/offset values, in micro-g's
'   Valid values: 0_000977 (0.000977g), 0_015625 (0.015625g)
'   Any other value polls the chip and returns the current setting
    curr_res := 0
    readreg(core#CTRL6_C, 1, @curr_res)
    case abiasres
        0_000977, 0_015625:
            abiasres := lookdownz(abiasres: 0_000977, 0_015625) << core#USR_OFF_W
        other:
            curr_res := (curr_res >> core#USR_OFF_W) & 1
            return lookupz(curr_res: 0_000977, 0_015625)

    abiasres := ((curr_res & core#USR_OFF_W_MASK) | abiasres)
    writereg(core#CTRL6_C, 1, @abiasres)

PUB AccelClearInt{}
' Clear Accelerometer interrupts

PUB AccelData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Read the Accelerometer output registers
    if _adata_src == ACCEL_LIVE
        readreg(core#OUTX_L_XL, 6, @tmp)
    else
        fifodata(@tmp, 3)
    long[ptr_x] := ~~tmp.word[X_AXIS]
    long[ptr_y] := ~~tmp.word[Y_AXIS]
    long[ptr_z] := ~~tmp.word[Z_AXIS]

PUB AccelDataOverrun{}: flag
' Flag indicating previously acquired data has been overwritten

PUB AccelDataRate(rate): curr_rate
' Set accelerometer output data rate, in Hz
'   Valid values:
'       Low power mode: 0, 1 (1.6), 12 (12.5), 26, 52
'       Normal mode: 0, 104, 208
'       High-perf mode: *0, 12, 26, 52, 104, 208, 416, 833, 1660, 3330, 6660
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

PUB AccelDataSource(src): curr_src
' Set source of data for AccelData() output
'   Valid values:
'      *ACCEL_LIVE (0): live/current data
'       ACCEL_FIFO (1): FIFO data
'   Any other value returns the current setting
    if (src == ACCEL_LIVE) or (src == ACCEL_FIFO)
        _adata_src := src
    else
        return _adata_src

PUB AccelInt{}: flag
' Flag indicating accelerometer interrupt asserted

PUB AccelLowPassFilter(freq): curr_freq
' Enable accelerometer data low-pass filter

PUB AccelOpMode(mode): curr_mode
' Set accelerometer operating mode
'   Valid values:
'      *XL_HIPERF (0): High-performance mode
'       XL_NORM (1): Normal mode
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CTRL6_C, 1, @curr_mode)
    case mode
        XL_NORM, XL_HIPERF:
            mode <<= core#XL_HM_MODE
        other:
            curr_mode := (curr_mode >> core#XL_HM_MODE) & 1

    mode := ((curr_mode & core#XL_HM_MODE_MASK) | mode)
    writereg(core#CTRL6_C, 1, @mode)

PUB AccelScale(scale): curr_scl
' Set the full-scale range of the accelerometer, in g's
'   Valid values: *2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    readreg(core#CTRL1_XL, 1, @curr_scl)
    case scale
        2, 4, 8, 16:
            scale := lookdownz(scale: 2, 16, 4, 8)
            _ares := lookupz(scale: 0_061, 0_488, 0_122, 0_244)
            scale <<= core#FS_XL
        other:
            curr_scl := ((curr_scl >> core#FS_XL) & core#FS_XL_BITS)
            return lookupz(curr_scl: 2, 16, 4, 8)
    scale := ((curr_scl & core#FS_XL_MASK) | scale)
    writereg(core#CTRL1_XL, 1, @scale)

PUB AccelSleepPwrMode(mode): curr_mode
' Set accelerometer power mode/oversampling mode, when sleeping
'   Valid values:
'       NORMAL (0): Normal
'       LOPWR (1): Accel Low power, gyro normal
'       LOPWR_GSLEEP (2): Accel Low power, gyro sleeps
'       LOPWR_GPWROFF (3): Accel Low power, gyro power off
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#TAP_CFG, 1, @curr_mode)
    case mode
        0..3:
            mode <<= core#INACT_EN
            mode |= core#INTS_ENA
        other:
            return ((curr_mode >> core#INACT_EN) & core#INACT_EN_BITS)

    mode := ((curr_mode & core#INACT_EN_MASK) | mode)
    writereg(core#TAP_CFG, 1, @mode)

PUB AutoSleepDataRate(rate): curr_rate
' Set accelerometer output data rate, in Hz, when in sleep mode
'   NOTE: Read-only; provided for API-compatibility only
'   Returns: 12
    return 12

PUB ClickAxisEnabled(mask): curr_mask
' Enable click detection per axis
'   Valid values:
'       %000..%111 (%XYZ)
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(core#TAP_CFG, 1, @curr_mask)
    case mask
        %000..%111:
            mask <<= core#TAP_EN
        other:
            return (curr_mask >> core#TAP_EN) & core#TAP_EN_BITS

    mask := ((curr_mask & core#TAP_EN_MASK) | mask)
    writereg(core#TAP_CFG, 1, @mask)

PUB Clicked{}: flag
' Flag indicating the sensor was single or double-clicked
'   Returns: TRUE (-1): sensor was clicked
    return ((clickedint{} & core#TAPPED) <> 0)

PUB ClickedInt{}: intstat
' Clicked interrupt status
'   Bit: 6..0:
'       6: Click detected
'       5: Single-click detected
'       4: Double-click detected
'       3: Click acceleration sign: 0 = positive, 1 = negative
'       2: Click detected on X-axis
'       1: Click detected on Y-axis
'       0: Click detected on Z-axis
    readreg(core#TAP_SRC, 1, @intstat)

PUB ClickIntEnabled(state): curr_state
' Enable click interrupts on INT1
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    readreg(core#TAP_CFG, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#INTS_EN
        other:
            return ((curr_state >> core#INTS_EN) == 1)

    state := ((curr_state & core#INTS_EN_MASK) | state)
    writereg(core#TAP_CFG, 1, @state)

PUB ClickIntsLatched(state): curr_state
' Enable latching click-detection interrupts
'   Valid values:
'       TRUE (-1 or 1): Interrupt asserted until status is read
'       FALSE (0): Interrupt asserted only for the event's duration
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#TAP_CFG, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state)
        other:
            return ((curr_state & 1) == 1)

    state := ((curr_state & core#LIR_MASK) | state)
    writereg(core#TAP_CFG, 1, @state)

PUB ClickLatency(clat): curr_clat
' Set minimum elapsed time between first recognized click and
'   subsequent click, in usec
'   Valid values: 4_800, 9_600, 19_200, 28_800
'   Any other value polls the chip and returns the current setting
    curr_clat := 0
    readreg(core#INT_DUR2, 1, @curr_clat)
    case clat
        4_800, 9_600, 19_200, 28_800:
            clat := lookdownz(clat: 4_800, 9_600, 19_200, 28_800) << core#QUIET
        other:
            curr_clat := ((curr_clat >> core#QUIET) & core#QUIET_BITS)
            return lookupz(curr_clat: 4_800, 9_600, 19_200, 28_800)

    clat := ((curr_clat & core#QUIET_MASK) | clat)
    writereg(core#INT_DUR2, 1, @clat)

PUB ClickThresh(thresh): curr_thr | ares
' Set threshold for recognizing a click, in microseconds
'   Valid values are AccelScale()-dependent
'       2g:     0..2_000_000    (step size: 0_062_500)
'       4g:     0..4_000_000    (step size: 0_125_000)
'       8g:     0..8_000_000    (step size: 0_250_000)
'       16g:    0..16_000_000   (step size: 0_500_000)
    ares := (accelscale(-2) * 1_000000) / 32    ' res. = scale / 32
    curr_thr := 0
    readreg(core#TAP_THS_6D, 1, @curr_thr)
    case thresh
        0..(32*ares):
            thresh := (thresh / ares)
        other:
            return (curr_thr * ares)

    thresh := ((curr_thr & core#TAP_THS_MASK) | thresh)
    writereg(core#TAP_THS_6D, 1, @thresh)

PUB ClickTime(ctime): curr_ctime
' Set maximum elapsed interval between start of click and end of click, in uSec
'   Valid values: 9_600, 19_200, 38_400, 57_600
'   Any other value polls the chip and returns the current setting
'   NOTE: AccelDataRate() should be set to 416Hz or 833Hz, per ST AN5040
    curr_ctime := 0
    readreg(core#INT_DUR2, 1, @curr_ctime)
    case ctime
        9_600, 19_200, 38_400, 57_600:
            ctime := lookdownz(ctime: 9_600, 19_200, 38_400, 57_600)
        other:
            curr_ctime := (curr_ctime & core#SHOCK_BITS)
            return lookupz(curr_ctime: 9_600, 19_200, 38_400, 57_600)

    ctime := ((curr_ctime & core#SHOCK_MASK) | ctime)
    writereg(core#INT_DUR2, 1, @ctime)

PUB ClockSource(src): curr_src
' Set sensor clock source

PUB DeviceID{}: id
' Read device identification
    readreg(core#WHO_AM_I, 1, @id)

PUB DoubleClickWindow(dctime): curr_dctime
' Set maximum elapsed interval between two consecutive clicks, in uSec

PUB FIFOAccelDec(factor): curr_factor
' Set decimation factor used to fill FIFO slots with accelerometer data
'   Valid values:
'       0: accel data not used in FIFO
'       1: no decimation (every accel sample used to fill FIFO)
'       2, 3, 4, 8, 16, 32: every n'th accel sample used to fill FIFO
'   Any other value polls the chip and returns the current setting
    curr_factor := 0
    readreg(core#FIFO_CTRL3, 1, @curr_factor)
    case factor
        0, 1, 2, 3, 4, 8, 16, 32:
            factor := lookdownz(factor: 0, 1, 2, 3, 4, 8, 16, 32) {
}           << core#DEC_FIFO_XL
        other:
            curr_factor := (curr_factor >> core#DEC_FIFO_XL)
            return lookupz(curr_factor: 0, 1, 2, 3, 4, 8, 16, 32)

    factor := ((curr_factor & core#DEC_FIFO_XL_MASK) | factor)
    writereg(core#FIFO_CTRL3, 1, @factor)

PUB FIFOData(ptr_data, nr_smp)
' Read FIFO data
    if lookdown(nr_smp: 1..FIFO_SAMPLES_MAX)
        readreg(core#FIFO_DATA_OUT_L, (nr_smp * FIFO_UNIT), ptr_data)

PUB FIFODataRate(rate): curr_rate
' Set FIFO output data rate, in Hz
'   Valid values:
'       0, 12, 26, 52, 104, 208, 416, 833, 1660, 3330, 6660
'   Any other value polls the chip and returns the current setting
'   NOTE: This setting will effectively be no higher than the sensor output
'       data rate (e.g., if AccelDataRate() and/or GyroDataRate() == 26,
'       the FIFO data will update at the same rate, even if it is set to 52)
    curr_rate := 0
    readreg(core#FIFO_CTRL5, 1, @curr_rate)
    case rate
        0, 12, 26, 52, 104, 208, 416, 833, 1660, 3330, 6660:
            rate := lookdownz(rate: 0, 12, 26, 52, 104, 208, 416, 833, 1660, {
}           3330, 6660) << core#ODR_FIFO
        other:
            curr_rate := ((curr_rate >> core#ODR_FIFO) & core#ODR_FIFO_BITS)
            return lookupz(curr_rate: 0, 12, 26, 52, 104, 208, 416, 833, 1660,{
}           3330, 6660)

    rate := ((curr_rate & core#ODR_FIFO_MASK) | rate)
    writereg(core#FIFO_CTRL5, 1, @rate)

PUB FIFOEmpty{}: flag
' Flag indicating FIFO is empty
'   Returns: TRUE (-1): FIFO empty, or FALSE (0): not empty
    flag := 0
    readreg(core#FIFO_STATUS2, 1, @flag)
    return ((flag & core#FIFOEMPTY) == core#FIFOEMPTY)

PUB FIFOEnabled(state): curr_state
' Enable FIFO memory

PUB FIFOFull{}: flag
' Flag indicating FIFO full
'   Returns: TRUE (-1): FIFO full, or FALSE (0): not full
    flag := 0
    readreg(core#FIFO_STATUS2, 1, @flag)
    return ((flag & core#FIFOFULL) == core#FIFOFULL)

PUB FIFOGyroDec(factor): curr_factor
' Set decimation factor used to fill FIFO slots with gyroscope data
'   Valid values:
'       0: gyro data not used in FIFO
'       1: no decimation (every gyro sample used to fill FIFO)
'       2, 3, 4, 8, 16, 32: every n'th gyro sample used to fill FIFO
'   Any other value polls the chip and returns the current setting
    curr_factor := 0
    readreg(core#FIFO_CTRL3, 1, @curr_factor)
    case factor
        0, 1, 2, 3, 4, 8, 16, 32:
            factor := lookdownz(factor: 0, 1, 2, 3, 4, 8, 16, 32) {
}           << core#DEC_FIFO_G
        other:
            curr_factor := (curr_factor >> core#DEC_FIFO_G)
            return lookupz(curr_factor: 0, 1, 2, 3, 4, 8, 16, 32)

    factor := ((curr_factor & core#DEC_FIFO_G_MASK) | factor)
    writereg(core#FIFO_CTRL3, 1, @factor)

PUB FIFOMode(mode): curr_mode
' Set FIFO mode
'   Valid values:
'       OFF (0): FIFO disabled/bypassed
'       FIFO (1): FIFO mode - stop when FIFO is full
'       CONT_TRIG (3): Continuously fill FIFO, overwriting the oldest samples
'           first, until trigger is deasserted, then transition to FIFO mode
'       OFF_TRIG (4): FIFO off until trigger is deasserted, then transition to
'           CONT mode
'       CONT (6): Continuously fill FIFO, overwriting the oldest samples first
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#FIFO_CTRL5, 1, @curr_mode)
    case mode
        OFF, FIFO, CONT_TRIG, OFF_TRIG, CONT:
        other:
            return (curr_mode & core#FIFO_MODE_BITS)

    mode := ((curr_mode & core#FIFO_MODE_MASK) | mode)
    writereg(core#FIFO_CTRL5, 1, @mode)

PUB FIFOOverrun{}: flag
' Flag indicating FIFO has overrun
'   Returns: TRUE (-1): FIFO overrun, or FALSE (0): FIFO not overrun
    flag := 0
    readreg(core#FIFO_STATUS2, 1, @flag)
    return ((flag & core#FIFOOVRRUN) == core#FIFOOVRRUN)

PUB FIFOReset{}
' Reset the FIFO

PUB FIFOSource(mask): curr_mask
' Set FIFO source data, as a bitmask

PUB FIFOThresh(level): curr_lvl
' Set FIFO watermark/threshold level, in words
    curr_lvl := 0
    readreg(core#FIFO_CTRL1, 2, @curr_lvl)
    case level
        0..FIFO_SAMPLES_MAX:
        other:
            return (curr_lvl & core#FTH_BITS)

    level := ((curr_lvl & core#FTH_MASK) | level)
    writereg(core#FIFO_CTRL1, 2, @level)

PUB FIFOUnreadSamples{}: nr_samples
' Number of unread samples stored in FIFO
    nr_samples := 0
    readreg(core#FIFO_STATUS1, 2, @nr_samples)
    return (nr_samples & core#DIFF_FIFO_BITS)

PUB FIFOWaterMark{}: flag
' Flag indicating FIFO watermark/threshold level reached
'   Returns:
'       TRUE (-1): FIFO level at or above FIFOThreshold()
'       FALSE (0): FIFO level below FIFOThreshold()
    flag := 0
    readreg(core#FIFO_STATUS2, 1, @flag)
    return ((flag & core#FIFOWTRMRK) == core#FIFOWTRMRK)

PUB FreeFallThresh(thresh): curr_thr
' Set free-fall threshold, in milli-g's
'   Valid values: 156, 219, 250, 312, 344, 406, 469, 500
'   Any other value polls the chip and returns the current setting
    curr_thr := 0
    readreg(core#FREE_FALL, 1, @curr_thr)
    case thresh
        156, 219, 250, 312, 344, 406, 469, 500:
            thresh := lookdownz(thresh: 156, 219, 250, 312, 344, 406, 469, 500)
        other:
            curr_thr &= core#FF_THS_BITS
            return lookupz(curr_thr: 156, 219, 250, 312, 344, 406, 469, 500)

    thresh := ((curr_thr & core#FF_THS_MASK) | thresh)
    writereg(core#FREE_FALL, 1, @thresh)

PUB FreeFallTime(fftime): curr_time | ffdur_b4_0, ffdur_b5
' Set minimum time duration required to recognize free-fall
    curr_time := 0
    readreg(core#WAKEUP_DUR, 2, @curr_time)
    case fftime
        0..63:
            ' bit 5 of the FF_DUR field is in the MSB of the WAKEUP_DUR reg,
            '   but the bottom five bits are the MSBits in the next reg
            ' they aren't situated such that they can simply be isolated (&),
            '   so isolate each part separately and combine them when writing
            ffdur_b5 := ((fftime >> 5) & 1) << 7
            ffdur_b4_0 := (fftime & %11111) << 11
            fftime := (ffdur_b5 | ffdur_b4_0)
        other:
            ffdur_b5 := ((curr_time >> 7) & 1) << 5
            ffdur_b4_0 := ((curr_time >> 11) & %11111)
            return (ffdur_b5 + ffdur_b4_0)

    fftime := ((curr_time & core#FF_DUR_MASK) | fftime)
    writereg(core#WAKEUP_DUR, 2, @fftime)

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
            longmove(bias_x, @_gbias, GYRO_DOF)
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
            longmove(@_gbias, @bias_x, GYRO_DOF)
        other:
            return

PUB GyroClearInt{}
' Clears out any interrupts set up on the Gyroscope and resets all Gyroscope interrupt registers to their default values.

PUB GyroData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Reads the Gyroscope output registers
    if _gdata_src == GYRO_LIVE
        readreg(core#OUTX_L_G, 6, @tmp)
    else
        fifodata(@tmp, 3)
    long[ptr_x] := ~~tmp.word[X_AXIS] - _gbias[X_AXIS]
    long[ptr_y] := ~~tmp.word[Y_AXIS] - _gbias[Y_AXIS]
    long[ptr_z] := ~~tmp.word[Z_AXIS] - _gbias[Z_AXIS]

PUB GyroDataOverrun{}: flag
' Dummy method

PUB GyroDataRate(rate): curr_rate
' Set gyroscope output data rate, in Hz
'   Valid values:
'       Low power mode: 0, 12 (12.5), 26, 52
'       Normal: 0, 104, 208
'       High-perf mode: *0, 12, 26, 52, 104, 208, 416, 833, 1660, 3330, 6660
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

PUB GyroDataSource(src): curr_src
' Set source of data for GyroData() output
'   Valid values:
'      *GYRO_LIVE (0): live/current data
'       GYRO_FIFO (1): FIFO data
'   Any other value returns the current setting
    if (src == GYRO_LIVE) or (src == GYRO_FIFO)
        _gdata_src := src
    else
        return _gdata_src

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
' Set gyroscope output data low-pass filter, in Hz
'   Valid values dependent on GyroDataRate() setting:
'       833: 155, 195, *245, 293
'       1660: 168, 224, *315, 505
'       3300: 172, 234, *343, 925
'       6600: 173, 237, *351, 937
'       When set to other data rates, this setting has no effect
'   Any other value polls the chip and returns the current setting
    curr_freq := 0
    readreg(core#CTRL6_C, 1, @curr_freq)
    case gyrodatarate(-2)
        833:
            case freq
                155, 195, 245, 293:
                    freq := lookdownz(freq: 245, 195, 155, 293)
                other:
                    curr_freq := (curr_freq & core#FTYPE_BITS)
                    return lookupz(curr_freq: 245, 195, 155, 293)
        1660:
            case freq
                168, 224, 315, 505:
                    freq := lookdownz(freq: 315, 224, 168, 505)
                other:
                    curr_freq := (curr_freq & core#FTYPE_BITS)
                    return lookupz(curr_freq: 315, 224, 168, 505)
        3330:
            case freq
                172, 234, 343, 925:
                    freq := lookdownz(freq: 343, 234, 172, 925)
                other:
                    curr_freq := (curr_freq & core#FTYPE_BITS)
                    return lookupz(curr_freq: 343, 234, 172, 925)
        6660:
            case freq
                173, 237, 351, 937:
                    freq := lookdownz(freq: 351, 237, 173, 937)
                other:
                    curr_freq := (curr_freq & core#FTYPE_BITS)
                    return lookupz(curr_freq: 351, 237, 173, 937)
        other:
            return

    freq := ((curr_freq & core#FTYPE_MASK) | freq)
    writereg(core#CTRL6_C, 1, @freq)

PUB GyroLowPower(state): curr_state
' Enable low

PUB GyroOpMode(mode): curr_mode
' Set gyroscope operating mode
'   Valid values:
'      *NORM (0): Normal operation
'       SLEEP (1): Sleep/low-power operation
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CTRL4_C, 1, @curr_mode)
    case mode
        NORM, SLEEP:
            mode <<= core#SLP
        other:
            return (curr_mode >> core#SLP) & 1

    mode := ((curr_mode & core#SLP_MASK) | mode)
    writereg(core#CTRL4_C, 1, @mode)

PUB GyroScale(scale): curr_scl
' Set gyroscope full-scale range, in degrees per second
'   Valid values: 125, *250, 500, 1000, 2000
'   Any other value polls the chip and returns the current setting
    curr_scl := 0
    readreg(core#CTRL2_G, 1, @curr_scl)
    case scale
        125, 250, 500, 1000, 2000:
            ' 125dps scale is a separate reg field from the other scales,
            ' but treat it as combined, for simplicity
            scale := lookdownz(scale: 250, 125, 500, 0, 1000, 0, 2000)
            _gres := lookupz(scale: 8_750, 4_375, 17_500, 0, 35_000, 0, 70_000)
            scale <<= core#FS_G
        other:
            curr_scl := (curr_scl >> core#FS_G) & core#FS_G_BITS
            return lookupz(curr_scl: 250, 125, 500, 0, 1000, 0, 2000)

    scale := ((curr_scl & core#FS_G_MASK) | scale)
    writereg(core#CTRL2_G, 1, @scale)

PUB InactThresh(thresh): curr_thr | thr_res, thr_max
' Set inactivity threshold, in micro-g's
'   Valid values: TBD
'   Any other value polls the chip and returns the current setting
    thr_res := ((accelscale(-2) * 1_000_000) / 64)
    thr_max := (thr_res * core#WK_THS_MAX)
    curr_thr := 0
    readreg(core#WAKEUP_THS, 1, @curr_thr)
    case thresh
        0..thr_max:
            thresh /= thr_res
        other:
            return ((curr_thr & core#WK_THS_BITS) * thr_res)

    thresh := ((curr_thr & core#WK_THS_MASK) | thresh)
    writereg(core#WAKEUP_THS, 1, @thresh)

PUB InactTime(itime): curr_itime | time_res, dur_max
' Set inactivity time, in milliseconds
'   Valid values:
'   Any other value polls the chip and returns the current setting
'   NOTE: Setting this to 0 will generate an interrupt when the acceleration
'       measures less than that set with InactThresh()
    time_res := (512_000 / acceldatarate(-2))
    dur_max := (time_res * core#SLP_DUR_MAX)
    curr_itime := 0
    readreg(core#WAKEUP_DUR, 1, @curr_itime)
    case itime
        0..dur_max:
            itime /= time_res
        other:
            return ((curr_itime & core#SLP_DUR_BITS) * time_res)

    writereg(core#WAKEUP_DUR, 1, @itime)

PUB InFreeFall{}: flag
' Flag indicating device is in free-fall
'   Returns:
'       TRUE (-1): device is in free-fall
'       FALSE (0): device isn't in free-fall
    flag := 0
    readreg(core#WAKEUP_SRC, 1, @flag)
    return ((flag & core#FREEFALL) == core#FREEFALL)

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
    flag := 0
    readreg(core#WAKEUP_SRC, 1, @flag)
    return (((flag >> core#SLPST_IA) & 1) == 1)

PUB IntLatchEnabled(state): curr_state
' Latch interrupt pin when interrupt asserted

PUB Int1Mask(mask): curr_mask
' Set INT1 pin interrupt mask
'   Valid values:
'       Bit 7..0
'       7 - Inactivity
'       6 - Single-tap
'       5 - Wakeup
'       4 - Free-fall
'       3 - Double-tap
'       2 - 6D
'       1 - Tilt
'       0 - Timer: counter ended
    case mask
        0..%11111111:
            writereg(core#MD1_CFG, 1, @mask)
        other:
            curr_mask := 0
            readreg(core#MD1_CFG, 1, @curr_mask)
            return

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
    return true

PUB MagFastRead(state): curr_state
' Enable reading of only the MSB of data to increase reading efficiency, at the cost of precision and accuracy

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

PUB Reset{} | tmp
' Reset the device
    tmp := core#RESET
    writereg(core#CTRL3_C, 1, @tmp)

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

PRI blockDataUpdate{} | tmp
' Enable block data updates
'   (wait until MSB and LSB registers are updated internally to update the
'   values stored therein)

    tmp := 0
    readreg(core#CTRL3_C, 1, @tmp)

    tmp |= (1 << core#BDU)

    writereg(core#CTRL3_C, 1, @tmp)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#OUT_TEMP_L..core#OUTZ_H_XL, core#OUT_MAG_RAW_X_L:

        core#FUNC_CFG_ACCESS, core#SENS_SYNC_TIMEFR..core#DRDY_PULSE_CFG_G, {
}       core#INT1_CTRL..core#STATUS, core#SENSHUB1..core#TIMESTAMP2, {
}       core#STP_TIMESTMP_L..core#WRIST_TILT_IA, {
}       core#TAP_CFG..core#SENS_SYNC_SPI_ERR, core#X_OFS_USR..core#Z_OFS_USR:
        other:                                  ' invalid reg_nr
            return
#ifdef LSM6DSL_I2C
    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start{}
    i2c.write(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}
#elseifdef LSM6DSL_SPI
    outa[_CS] := 0
    spi.wr_byte(reg_nr | core#READ)

    ' read LSByte to MSByte
    spi.rdblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1
#endif

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        core#FUNC_CFG_ACCESS, core#SENS_SYNC_TIMEFR..core#DRDY_PULSE_CFG_G, {
}       core#INT1_CTRL, core#INT2_CTRL, core#CTRL1_XL..core#MASTER_CFG, {
}       core#TIMESTAMP2, core#TAP_CFG..core#SENS_SYNC_SPI_ERR, {
}       core#X_OFS_USR..core#Z_OFS_USR:
        other:
            return

#ifdef LSM6DSL_I2C
    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_lsbf(ptr_buff, nr_bytes)
    i2c.stop{}
#elseifdef LSM6DSL_SPI
    outa[_CS] := 0
    spi.wr_byte(reg_nr)

    ' write LSByte to MSByte
    spi.wrblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1
#endif

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
