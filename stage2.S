bits 16
org 0x10000

dw 0x4349


; Independent project within the Nexis ecosystem
; Copyright (c) 2026 icarotelesdasilva


; NOTE:
; The code was tested and evaluated on actual hardware.
; All information regarding the A20 gate was taken from the following
; reference source (wiki.osdev.org).
; source: (wiki.osdev.org/A20_Line#Fast_A20_Gate)

; To enter protected mode, you should first disable interrupts and set
; up the Global Descriptor Table. After that, set the PE bit of CR0.
; Remember to disable interrupts to avoid a triple fault; that's not fun :>)


stage2:


; It is necessary to enable A20 to enter 32-bit protected mode, but since
; we already activated it in stage one, there is no reason to activate it
; here, given that I will be linking the files.


; disable interrupts

cli


; load GDT

; The stage 2 code is loaded at physical address 0x10000.
; Because we are still in 16-bit mode, the GDT descriptor is located
; above the 64 KiB boundary.
;
; Therefore, use a 32-bit effective address to access it.

lgdt [dword gdt_descriptor]


; enable protected mode in CR0

mov eax, cr0
or eax, 1
mov cr0, eax


; Far Jump to clear the pipeline and load CS with 0x08.
;
; The code segment is a 32-bit code segment, so the far jump must
; use a 32-bit offset.

jmp dword 0x08:start_protected_mode


; _____ entering 32-bit mode ______

bits 32


start_protected_mode:


; Now, for 32-bit mode, it is essential to configure the segments—
; just as we did in real mode.

mov ax, 0x10

mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax


; Configure the stack for protected mode.
;
; The data segment has a base address of 0x00000000,
; so ESP 0x90000 corresponds to physical address 0x90000.

mov esp, 0x90000


; In this specific situation, my kernel attempts to jump directly to
; 0x10200, so if the kernel jumps here, we execute the following
; which is "jmp 0x10200" to jump directly to the main kernel
; located there.

jmp 0x10200


hang:

        cli

.loop:

        hlt
        jmp .loop


gdt_start:


        ; Null descriptor

        dd 0, 0


        ; Code segment
        ;
        ; Base address  = 0x00000000
        ; Limit         = 0xFFFFFFFF
        ; 32-bit code segment

        dw 0xFFFF, 0x0000
        db 0x00, 10011010b, 11001111b, 0x00


        ; Data segment
        ;
        ; Base address  = 0x00000000
        ; Limit         = 0xFFFFFFFF
        ; 32-bit data segment

        dw 0xFFFF, 0x0000
        db 0x00, 10010010b, 11001111b, 0x00


gdt_end:


gdt_descriptor:

        dw gdt_end - gdt_start - 1
        dd gdt_start


; I really hate the GDT.


times 512 - ($ - $$) db 0
