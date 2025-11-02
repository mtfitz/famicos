;; USE EITHER FME-7 (PREFERABLE) OR MMC5 FOR PRG-RAM/ROM BANK SWITCHING

RAM_ZEROPAGE_PTR                = $0000
RAM_STACK_PTR                   = $0100
CART_ZEROPAGE_SWAP              = $7800
CART_STACK_SWAP                 = $7900
FME7_COMMAND_OUT                = $8000
FME7_PARAM_OUT                  = $A000
FME7_CART_RAM_SWITCH_COMMAND    = $08
FME7_CART_RAM_SWITCH_PARAM      = $C0

USER_CPU_REG_A_SAVE_PTR         = $7A00
USER_CPU_REG_X_SAVE_PTR         = $7A01
USER_CPU_REG_Y_SAVE_PTR         = $7A02
USER_CPU_REG_S_SAVE_PTR         = $7A03
USER_CPU_REG_P_SAVE_PTR         = $7A04
USER_CPU_REG_PCL_SAVE_PTR       = $7A05
USER_CPU_REG_PCH_SAVE_PTR       = $7A06

.segment "DATA"

kernel_cur_user_pid:                .byte 0

.segment "CODE"

;; YIELD

yield:
    ; ROADMAP:
    ; 1. save user registers
    ; 2. save user ZP + stack
    ; 3. select kernel bank
    sei
@save_user_cpu_regs:
    ; stack should already contain P,PCL,PCH from last user process
    sta USER_CPU_REG_A_SAVE_PTR
    stx USER_CPU_REG_X_SAVE_PTR
    sty USER_CPU_REG_Y_SAVE_PTR
    tsx
    stx USER_CPU_REG_S_SAVE_PTR
    pla
    sta USER_CPU_REG_P_SAVE_PTR
    pla
    sta USER_CPU_REG_PCL_SAVE_PTR
    pla
    sta USER_CPU_REG_PCH_SAVE_PTR

@transfer_cpu_ram_to_swap:
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
@switch_to_kernel_memory:
    ; FME-7: switch to kernel RAM bank (0)
    lda #FME7_CART_RAM_SWITCH_COMMAND
    sta FME7_COMMAND_OUT
    lda #FME7_CART_RAM_SWITCH_PARAM
    sta FME7_PARAM_OUT
    ; jmp kernel_main
kernel_main:
    ; TODO: add this in another file
    jmp kernel_main

;; RESUME

resume:
    ; ROADMAP:
    ; 1. select user process bank
    ; 2. restore user ZP + stack
    ; 3. restore user registers
@switch_to_user_memory
    ; FME-7: switch to user RAM bank
    lda #FME7_CART_RAM_SWITCH_COMMAND
    sta FME7_COMMAND_OUT
    lda #FME7_CART_RAM_SWITCH_PARAM
    eor kernel_cur_user_pid
    sta FME7_PARAM_OUT
@transfer_swap_to_cpu_ram:
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
@restore_user_cpu_regs:
    lda USER_CPU_REG_PCH_SAVE_PTR
    pha
    lda USER_CPU_REG_PCL_SAVE_PTR
    pha
    lda USER_CPU_REG_P_SAVE_PTR
    pha
    ldx USER_CPU_REG_S_SAVE_PTR
    txs
    lda USER_CPU_REG_A_SAVE_PTR
    ldx USER_CPU_REG_X_SAVE_PTR
    ldy USER_CPU_REG_Y_SAVE_PTR
@goto_user:
    cli
    rts