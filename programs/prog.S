.data
sseg: .byte 0x03,0x9F,0x25,0x0D,0x99,0x49,0x41,0x1F,0x01,0x09 # LUT for 7-segs

.text
init:
    li s0, 0x1100C008           # addr for anodes
    li s1, 0x1100C004           # addr for sseg
    la s2, sseg                 # addr for sseg LUT
    li s3, 0x1100D000           # TC CSR port address
    li s4, 0x1100D004           # TC count port address
    li s5, 0x11008004           # btn port address
    li s6, 0x30                 # const 30 in BCD
    li s7, 10                   # const 10
    li s8, 0xff                  # debounce length 
    la t0, ISR                  # load ISR address into t0
    csrrw zero, mtvec, t0       # set mtvec to ISR address

    li t0, 0x000CB735           # blink rate
    sw t0, 0(s4)                # init TC count 
    li t0, 0x01                 # init TC CSR
    sw t0, 0(s3)                # no prescale, turn on TC

    li a0, 0                    # intr count
    li a1, 0                    # clear count down flag
    li a2, 0                    # clear segment flag
unmask:
    li t0, 0x8                  # enable interrupts
    csrrs zero, mstatus, t0     # enable interrupts
clear: 
    li t0, 0                    # init t0 accumulator
loop: 
    lbu t1, 0(s5)               # get button data
    andi t1, t1, 0x4            # mask LSB
    beq t1, zero, clear         # if button is off, clear and continue polling
    addi t0, t0, 1              # accumulate
    bne t0, s8, loop            # loop if button has not been on for req length

count_down:
    beq a1, zero, count_up      # if count down flag is 0, count up
    andi t0, a0, 0xF            # mask low nibble
    beq t0, zero, borrow        # if low nibble is 0, go to borrow
    addi a0, a0, -1             # decrement BCD
    bne a0, zero, rel_clear     # if BCD is not 0, go to rel_clear
    li a1, 0                    # clear count down flag
    j rel_clear                 # go to rel_clear
borrow:
    addi a0, a0, -7             # decrement high nibble, set low nibble to 9
    j rel_clear                 # go to rel_clear

count_up:
    addi a0, a0, 1              # increment BCD
    andi t0, a0, 0xF            # mask low nibble
    blt t0, s7, rel_clear       # if low nibble is less than 10, go to rel_clear
    addi a0, a0, 6              # add 6 to BCD
    bne a0, s6, rel_clear       # if BCD is not 30, go to rel_clear
    li a1, 1                    # set count down flag

rel_clear:
    li t0, 0                    # init t0 accumulator
rel_loop:
    lbu t1, 0(s5)               # get button data
    andi t1, t1, 0x4            # mask LSB
    bne t1, zero, rel_clear     # if button is on, clear and continue
    addi t0, t0, 1              # accumulate
    bne t0, s8, rel_loop        # loop if button has not been on for req length
    j clear
#--------------------------------------------------------------
# Interrupt Service Routine
#  desc: mulitplexes the 7-seg display
#--------------------------------------------------------------
ISR:
    xori a2, a2, 1              # toggle segment flag
    beq a2, zero, set_ones      # if flag is 0, set ones
set_tens:
    andi t6, a0, 0xF0           # mask high nibble
    beq t6, zero, ISR_ret       # if high nibble is 0, return
    srli t6, t6, 4              # shift a0 right by 4
    add t6, t6, s2              # get sseg LUT addr
    lbu t6, 0(t6)               # get sseg value
    sb t6, 0(s1)                # output sseg value
    li t6, 0xD                  # 2nd rightmost AN on
    sb t6, 0(s0)                # output AN value 
    j ISR_ret                   # return from ISR
set_ones:
    andi t6, a0, 0xF            # mask low nibble
    add t6, t6, s2              # get sseg LUT addr
    lbu t6, 0(t6)               # get sseg value
    sb t6, 0(s1)                # output sseg value
    li t6, 0xE                  # rightmost AN on
    sb t6, 0(s0)                # output AN value 
ISR_ret:
    mret                   # returns with interrupts unmasked

