;
; Handcrafted x86 Kernel Bootloader
;
; Independent project within the Nexis ecosystem
;
; Copyright (c) 2026 icarotelesdasilva
; Licensed under the MIT License

        bits 16
        org 0x7c00

        jmp start

%ifndef TOTAL_SECTORS
%define TOTAL_SECTORS 2
%endif
 ; Since the Makefile automatically calculates the bootloader stage, we need it to know where the NASM definition is being used.


boot_drive      db 0


start:

        cli

        xor ax, ax
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, 0x9000

        mov [boot_drive], dl


        ; Enable the A20 line using the Fast A20 Gate.

        in al, 0x92
        or al, 2
        and al, 0xFE
        out 0x92, al


        ; Check whether the BIOS supports INT 13h Extensions (EDD).

        mov ah, 0x41
        mov bx, 0x55AA
        mov dl, [boot_drive]

        int 0x13
        jc chs

        cmp bx, 0xAA55
        jne chs

        test cx, 0x0001
        jz chs

        jmp lba


chs:


        ; Load stage 2 and the kernel into memory.
        ;
        ; ES:BX = 1000:0000
        ; Physical address = 0x10000
        ;
        ; Sector 2 is loaded to 0x10000.
        ; Stage 2 occupies the first sector.
        ; The kernel starts immediately after stage 2 at 0x10200.

        mov ax, 0x1000
        mov es, ax
        xor bx, bx

        mov ah, 0x02
        mov al, TOTAL_SECTORS ; We include here the section that the makefile would have generated.

        mov ch, 0
        mov cl, 2
        mov dh, 0
        mov dl, [boot_drive]

        int 0x13
        jc disk_error

        jmp loaded


lba:


        ; Load stage 2 and the kernel using INT 13h Extensions (LBA).

        mov ax, 0x1000
        mov es, ax
        xor bx, bx

        mov si, dap

        ; Disk Address Packet size.

        mov word [si + 0], 0x0010

        ; Number of sectors to read.

        mov word [si + 2], TOTAL_SECTORS

        ; Buffer offset.
        ;
        ; ES:BX = 1000:0000
        ; Physical address = 0x10000

        mov word [si + 4], 0x0000
        mov word [si + 6], 0x1000

        ; Starting LBA.
        ;
        ; LBA 0 = boot sector.
        ; LBA 1 = stage 2.
        ;
        ; Therefore we start reading from LBA 1.

        mov dword [si + 8], 0x00000001
        mov dword [si + 12], 0x00000000

        mov ah, 0x42
        mov dl, [boot_drive]

        int 0x13
        jc disk_error

        jmp loaded


loaded:

        mov ax, 0x1000
        mov es, ax

        ; Check the stage 2 signature.
        ;
        ; 0x4349 is stored in little-endian as:
        ;
        ; 49 43
        ;
        ; which represents the characters "IC".

        cmp word [es:0x0000], 0x4349
        jne signature_error

        ; Jump to stage 2.
        ;
        ; 1000:0002 = physical address 0x10002.
        ;
        ; The first two bytes contain the "IC" signature.

        jmp 0x1000:0x0002


signature_error:


        mov ax, 0xB800
        mov ds, ax

        mov byte [0x00], 'S'
        mov byte [0x01], 0x0C

        jmp hang


disk_error:


        mov ax, 0xB800
        mov ds, ax

        mov byte [0x00], 'D'
        mov byte [0x01], 0x0C

        jmp hang


hang:


        cli

.loop:

        hlt
        jmp .loop


dap:


        times 510 - ($ - $$) db 0
        dw 0xAA55
