;; USE EITHER FME-7 (PREFERABLE) OR MMC5 FOR PRG-RAM/ROM BANK SWITCHING

RAM_ZEROPAGE_PTR                = $0000
RAM_STACK_PTR                   = $0100
CART_ZEROPAGE_SWAP              = $7800
CART_STACK_SWAP                 = $7900
FME7_COMMAND_OUT                = $8000
FME7_PARAM_OUT                  = $A000
FME7_CART_RAM_SWITCH_COMMAND    = $08
FME7_CART_RAM_SWITCH_PARAM      = $C0

.segment "DATA"

kernel_cur_user_pid:                .byte 0

.segment "CODE"

;; YIELD

yield:
    sei
    ; TODO: save user registers
    ; jmp transfer_cpu_ram_to_swap

transfer_cpu_ram_to_swap:
    ldx     #0
@loop:
    lda     RAM_ZEROPAGE_PTR,x
    sta     CART_ZEROPAGE_SWAP,x
    lda     RAM_STACK_PTR,x
    sta     CART_STACK_SWAP,x
    txa
    cmp     #$ff
    beq     @end
    inx
    jmp     @loop
@end:
    ; jmp goto_kernel

goto_kernel:
    ; FME-7: switch to kernel RAM bank (0)
    lda #FME7_CART_RAM_SWITCH_COMMAND
    sta FME7_COMMAND_OUT
    lda #FME7_CART_RAM_SWITCH_PARAM
    sta FME7_PARAM_OUT
    jmp kernel_main

kernel_main:
    ; TODO: put this in another file
    jmp kernel_main

;; RESUME

resume:
    ; TODO: load user registers
    jmp transfer_swap_to_cpu_ram

transfer_swap_to_cpu_ram:
    ldx     #0
@loop:
    lda     RAM_ZEROPAGE_PTR,x
    sta     CART_ZEROPAGE_SWAP,x
    lda     RAM_STACK_PTR,x
    sta     CART_STACK_SWAP,x
    txa
    cmp     #$ff
    beq     @end
    inx
    jmp     @loop
@end:
    jmp goto_user

goto_user:
    ; TODO: finish this
    lda #FME7_CART_RAM_SWITCH_COMMAND
    sta FME7_COMMAND_OUT
    lda #FME7_CART_RAM_SWITCH_PARAM
    eor kernel_cur_user_pid
    sta FME7_PARAM_OUT
    cli
    jmp goto_user