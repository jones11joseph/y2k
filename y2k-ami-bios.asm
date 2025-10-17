assembly

; This code is written for NASM (Netwide Assembler)
; It creates a bootable program that interacts with a PC's hardware,
; including one with an AMI BIOS.

ORG 0x7C00              ; BIOS loads the boot sector to address 0x7C00

BOOT_MSG DB "AMI BIOS Date Demo", 0xD, 0xA
         DB "DD-MM-YYYY format", 0xD, 0xA, 0x0
         
DATE_BUF DB "  -  -    ", 0x0

; CMOS ports and registers
CMOS_ADDR_PORT EQU 70h
CMOS_DATA_PORT EQU 71h
REG_DAY        EQU 07h
REG_MONTH      EQU 08h
REG_YEAR       EQU 09h
REG_CENTURY    EQU 32h

; Main entry point
START:
    ; Set up segments
    MOV AX, CS
    MOV DS, AX
    MOV ES, AX

    ; --- Print boot message ---
    MOV SI, BOOT_MSG
    CALL PRINT_STRING

    ; --- Get date from RTC/CMOS ---
    CALL GET_DATE_RTC
    
    ; --- Format date and display ---
    CALL FORMAT_AND_PRINT

    ; --- Halt the system ---
    CLI
    HLT

; --- Print string subroutine ---
PRINT_STRING:
    ; Input: SI = offset of string
    ; Clobbers: AX, BX, SI
    MOV AH, 0x0E        ; BIOS teletype function
    .loop:
        LODSB           ; Load byte from SI into AL
        CMP AL, 0x0
        JE .end_loop
        INT 0x10        ; BIOS video interrupt
        JMP .loop
    .end_loop:
    RET

; --- Get date from RTC/CMOS subroutine ---
GET_DATE_RTC:
    ; Retrieves date from CMOS and stores in memory locations
    ; Clobbers: AL, DX, AX
    ; Disable interrupts for safe CMOS access
    CLI
    
    ; Read day
    MOV AL, REG_DAY
    OUT CMOS_ADDR_PORT, AL
    IN AL, CMOS_DATA_PORT
    MOV [BYTE day_bcd], AL

    ; Read month
    MOV AL, REG_MONTH
    OUT CMOS_ADDR_PORT, AL
    IN AL, CMOS_DATA_PORT
    MOV [BYTE month_bcd], AL

    ; Read year
    MOV AL, REG_YEAR
    OUT CMOS_ADDR_PORT, AL
    IN AL, CMOS_DATA_PORT
    MOV [BYTE year_bcd], AL

    ; Read century
    MOV AL, REG_CENTURY
    OUT CMOS_ADDR_PORT, AL
    IN AL, CMOS_DATA_PORT
    MOV [BYTE century_bcd], AL

    STI ; Re-enable interrupts
    RET

; --- Format and print date subroutine ---
FORMAT_AND_PRINT:
    ; Formats the date_buf with BCD values
    ; Clobbers: AL, AH
    
    ; Format Day (DD)
    MOV AL, [BYTE day_bcd]
    CALL BCD_TO_ASCII
    MOV [BYTE DATE_BUF], AH
    MOV [BYTE DATE_BUF+1], AL

    ; Format Month (MM)
    MOV AL, [BYTE month_bcd]
    CALL BCD_TO_ASCII
    MOV [BYTE DATE_BUF+3], AH
    MOV [BYTE DATE_BUF+4], AL

    ; Format Year (YYYY)
    MOV AL, [BYTE century_bcd]
    CALL BCD_TO_ASCII
    MOV [BYTE DATE_BUF+6], AH
    MOV [BYTE DATE_BUF+7], AL

    MOV AL, [BYTE year_bcd]
    CALL BCD_TO_ASCII
    MOV [BYTE DATE_BUF+8], AH
    MOV [BYTE DATE_BUF+9], AL
    
    MOV SI, DATE_BUF
    CALL PRINT_STRING
    RET

; --- BCD to ASCII conversion subroutine ---
BCD_TO_ASCII:
    ; Converts a BCD byte in AL to two ASCII characters in AH and AL
    ; Input: AL = BCD byte (e.g., 25h)
    ; Output: AH = ASCII tens digit, AL = ASCII units digit
    ; Clobbers: BL
    PUSH BX
    MOV BH, AL
    AND AL, 0x0F
    ADD AL, '0'
    MOV BL, AL

    MOV AL, BH
    AND AL, 0xF0
    MOV CL, 4
    SHR AL, CL
    ADD AL, '0'
    
    MOV AH, AL
    MOV AL, BL
    POP BX
    RET

; --- BCD storage for date components ---
day_bcd   DB 0
month_bcd DB 0
year_bcd  DB 0
century_bcd DB 0

; --- Pad with zeros up to 510 bytes, add boot signature ---
TIMES 510-($-$$) DB 0
DW 0xAA55
