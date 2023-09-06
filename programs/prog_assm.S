init:
    li s0, 0x1100C008           # addr for switches
    li s1, 0x1100C004           # addr for led
    la t0, ISR                  # addr for ISR
    csrrw zero, mtvec, t0       # set mtvec to ISR addr 
    li a7, 0                    # clear intr flag

    li a0, 0                    # most recent btn value
    li a1, 0                    # 2nd most recent btn value
    li a2, 0                    # 3rd most recent btn value
    li a3, 0                    # 4th most recent btn value
    li a4, 0                    # avg
unmask:
    li t0, 0x8
    csrrs zero, mstatus, t0     # unmask intr
loop:
    sw a4, 0(s1)                # display avg
    beq a7, zero, loop          # wait for intr

shift_val:
    lhu t0, 0(s0)               # read switches
    mv a3, a2                   # shift values
    mv a2, a1                   # shift values
    mv a1, a0                   # shift values
    mv a0, t0                   # shift values
get_avg:
    add a4, a0, a1              # add values
    add a4, a4, a2              # add values
    add a4, a4, a3              # add values
    srli a4, a4, 2              # divide by 4
    j unmask

ISR:
    xori a7, a7, 1              # set intr flag
    li t0, 0x80
    csrrc zero, mstatus, t0     # mask intr
    mret
