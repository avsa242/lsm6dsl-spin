{
    --------------------------------------------
    Filename: core.con.lsm6dsl.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2021
    Started Feb 18, 2021
    Updated Feb 20, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    SPI_MAX_FREQ        = 10_000_000            ' device max SPI bus freq
    SPI_MODE            = 0                     ' 0 or 3
    T_POR               = 35_000                ' startup time (usecs)

    DEVID_RESP          = $6A                   ' device ID expected response

    READ                = 1 << 7                ' R/W bit: read

' Register definitions
    FUNC_CFG_ACCESS     = $01
    SENS_SYNC_TIMEFR    = $04
    SENS_SYNC_RESRATIO  = $05
    FIFO_CTRL1          = $06
    FIFO_CTRL2          = $07
    FIFO_CTRL3          = $08
    FIFO_CTRL4          = $09
    FIFO_CTRL5          = $0A
    DRDY_PULSE_CFG_G    = $0B
    INT1_CTRL           = $0D
    INT2_CTRL           = $0E
    WHO_AM_I            = $0F

    CTRL1_XL            = $10
    CTRL1_XL_MASK       = $FF
        ODR_XL          = 4
        FS_XL           = 2
        LPF1_BW_SEL     = 1
        BW0_XL          = 0
        ODR_XL_BITS     = %1111
        FS_XL_BITS      = %11
        ODR_XL_MASK     = (ODR_XL_BITS << ODR_XL) ^ CTRL1_XL_MASK
        FS_XL_MASK      = (FS_XL_BITS << FS_XL) ^ CTRL1_XL_MASK
        LPF1_BW_SEL_MASK= (1 << LPF1_BW_SEL) ^ CTRL1_XL_MASK
        BW0_XL_MASK     = 1 ^ CTRL1_XL_MASK

    CTRL2_G             = $11
    CTRL2_G_MASK        = $FE
        ODR_G           = 4
        FS_G            = 1                     ' FS_125 combined w/FS_G
        FS125_G         = 1
        ODR_G_BITS      = %1111
        FS_G_BITS       = %111
        ODR_G_MASK      = (ODR_G_BITS << ODR_G) ^ CTRL2_G_MASK
        FS_G_MASK       = (FS_G_BITS << FS_G) ^ CTRL2_G_MASK
        FS125_G_MASK    = (1 << FS125_G) ^ CTRL2_G_MASK

    CTRL3_C             = $12
    CTRL4_C             = $13
    CTRL5_C             = $14
    CTRL6_C             = $15
    CTRL7_G             = $16
    CTRL8_XL            = $17
    CTRL9_XL            = $18
    CTRL10_C            = $19
    MASTER_CFG          = $1A
    WAKEUP_SRC          = $1B
    TAP_SRC             = $1C
    D6D_SRC             = $1D

    STATUS              = $1E
    STATUS_MASK         = $07
        TDA             = 2
        GDA             = 1
        XLDA            = 0
        TRDY            = (1 << TDA)
        GRDY            = (1 << GDA)
        XLRDY           = (1 << XLDA)

    OUT_TEMP_L          = $20
    OUT_TEMP_H          = $21

    OUTX_L_G            = $22
    OUTX_H_G            = $23
    OUTY_L_G            = $24
    OUTY_H_G            = $25
    OUTZ_L_G            = $26
    OUTZ_H_G            = $27

    OUTX_L_XL           = $28
    OUTX_H_XL           = $29
    OUTY_L_XL           = $2A
    OUTY_H_XL           = $2B
    OUTZ_L_XL           = $2C
    OUTZ_H_XL           = $2D

    SENSHUB1            = $2E
    SENSHUB2            = $2F
    SENSHUB3            = $30
    SENSHUB4            = $31
    SENSHUB5            = $32
    SENSHUB6            = $33
    SENSHUB7            = $34
    SENSHUB8            = $35
    SENSHUB9            = $36
    SENSHUB10           = $37
    SENSHUB11           = $38
    SENSHUB12           = $39
    FIFO_STATUS1        = $3A
    FIFO_STATUS2        = $3B
    FIFO_STATUS3        = $3C
    FIFO_STATUS4        = $3D
    FIFO_DATA_OUT_L     = $3E
    FIFO_DATA_OUT_H     = $3F
    TIMESTAMP0          = $40
    TIMESTAMP1          = $41
    TIMESTAMP2          = $42
    STP_TIMESTMP_L      = $49
    STP_TIMESTMP_H      = $4A
    STP_CNTR_L          = $4B
    STP_CNTR_H          = $4C
    SENSHUB13           = $4D
    SENSHUB14           = $4E
    SENSHUB15           = $4F
    SENSHUB16           = $50
    SENSHUB17           = $51
    SENSHUB18           = $52
    FUNC_SRC1           = $53
    FUNC_SRC2           = $54
    WRIST_TILT_IA       = $55
    TAP_CFG             = $58
    TAP_THS_6D          = $59
    INT_DUR2            = $5A
    WAKEUP_THS          = $5B
    WAKEUP_DUR          = $5C
    FREE_FALL           = $5D
    MD1_CFG             = $5E
    MD2_CFG             = $5F
    MAST_CMD_CODE       = $60
    SENS_SYNC_SPI_ERR   = $61
    OUT_MAG_RAW_X_L     = $66
    OUT_MAG_RAW_X_H     = $67
    OUT_MAG_RAW_Y_L     = $68
    OUT_MAG_RAW_Y_H     = $69
    OUT_MAG_RAW_Z_L     = $6A
    OUT_MAG_RAW_Z_H     = $6B
    X_OFS_USR           = $73
    Y_OFS_USR           = $74
    Z_OFS_USR           = $75


PUB Null{}
' This is not a top-level object

