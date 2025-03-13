.text
.global _start

_start:
    mov r0, #4
    mov r1, #7
    mov r5, #0
    mov r4, sp
    strb r1, [r4, r5]!

_presuma:
    add r2, r0, r1
    ldrb r3, [r4, r5]!
    add r4, r1, r3

_suma:
    mov r7, #4
    swi 0
    mov r7, #1
    swi 0
