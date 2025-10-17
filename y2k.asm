assembly

.MODEL SMALL
.STACK 100h
.DATA
    ; Buffer to store the formatted date string (DD-MM-YYYY)
    date_str DB 'DD-MM-YYYY', 0

    ; CMOS port addresses
    cmos_address_port EQU 70h
    cmos_data_port    EQU 71h

    ; CMOS register numbers for RTC data
    reg_year   EQU 09h
    reg_month  EQU 08h
    reg_day    EQU 07h
    reg_century EQU 32h

    ; DOS print message
    msg_get    DB 'Current date is: ', '$'
    msg_set_ok DB 0Ah, 0Dh, 'Date set successfully!', '$'
    msg_read_err DB 0Ah, 0Dh, 'Error reading from RTC.', '$'

.CODE
START:
    ; Initialize data segment
    MOV AX, @DATA
    MOV DS, AX

    ; --- Retrieve date from BIOS and display ---
    MOV DX, OFFSET msg_get
    MOV AH, 09h
    INT 21h               ; Print "Current date is: "

    CALL GET_DATE_RTC     ; Retrieve date from CMOS
    CALL FORMAT_DATE      ; Format it in DD-MM-YYYY
    MOV DX, OFFSET date_str
    MOV AH, 09h
    INT 21h               ; Print formatted date

    ; --- Store a new date (for demonstration) ---
    ; In a real application, you would get this from user input.
    ; For example, set date to 16-10-2025 (in BCD).
    ; We need to disable interrupts during CMOS write to prevent corruption.
    CLI                   ; Disable interrupts

    MOV AL, reg_day
    OUT cmos_address_port, AL
    MOV AL, 16h           ; Day 16 (BCD)
    OUT cmos_data_port, AL

    MOV AL, reg_month
    OUT cmos_address_port, AL
    MOV AL, 10h           ; Month 10 (BCD)
    OUT cmos_data_port, AL

    MOV AL, reg_year
    OUT cmos_address_port, AL
    MOV AL, 25h           ; Year 25 (BCD)
    OUT cmos_data_port, AL

    MOV AL, reg_century
    OUT cmos_address_port, AL
    MOV AL, 20h           ; Century 20 (BCD)
    OUT cmos_data_port, AL

    STI                   ; Re-enable interrupts

    MOV DX, OFFSET msg_set_ok
    MOV AH, 09h
    INT 21h               ; Print success message

    ; --- Exit to DOS ---
    MOV AX, 4C00h
    INT 21h

; --- Subroutine to get date from RTC ---
GET_DATE_RTC PROC
    ; This procedure reads the raw date values from the RTC/CMOS.
    ; It assumes the RTC is not currently being updated.
    
    ; Read day
    MOV AL, reg_day
    OUT cmos_address_port, AL
    IN AL, cmos_data_port
    MOV [day_bcd], AL

    ; Read month
    MOV AL, reg_month
    OUT cmos_address_port, AL
    IN AL, cmos_data_port
    MOV [month_bcd], AL

    ; Read year
    MOV AL, reg_year
    OUT cmos_address_port, AL
    IN AL, cmos_data_port
    MOV [year_bcd], AL

    ; Read century
    MOV AL, reg_century
    OUT cmos_address_port, AL
    IN AL, cmos_data_port
    MOV [century], AL

    RET
GET_DATE_RTC ENDP

; --- Subroutine to format BCD date to ASCII DD-MM-YYYY string ---
FORMAT_DATE PROC
    ; Format Day (DD)
    MOV AL, [day_bcd]
    CALL BCD_TO_ASCII
    MOV [date_str], AH
    MOV [date_str+1], AL

    ; Format Month (MM)
    MOV AL, [month_bcd]
    CALL BCD_TO_ASCII
    MOV [date_str+3], AH
    MOV [date_str+4], AL

    ; Format Year (YYYY)
    MOV AL, [century]
    CALL BCD_TO_ASCII
    MOV [date_str+6], AH
    MOV [date_str+7], AL

    MOV AL, [year_bcd]
    CALL BCD_TO_ASCII
    MOV [date_str+8], AH
    MOV [date_str+9], AL

    RET
FORMAT_DATE ENDP

; --- BCD_TO_ASCII Subroutine ---
BCD_TO_ASCII PROC
    ; Converts a BCD byte in AL to two ASCII characters (tens and units).
    ; Example: 25h -> '2', '5'
    PUSH BX
    MOV BH, AL
    AND AL, 0Fh
    ADD AL, '0'
    MOV BL, AL          ; Store units digit in BL
    
    MOV AL, BH
    AND AL, 0F0h
    MOV CL, 04h
    SHR AL, CL          ; Shift tens digit to lower nibble
    ADD AL, '0'
    
    MOV AH, AL          ; Move tens digit to AH
    MOV AL, BL          ; Move units digit back to AL
    POP BX
    RET
BCD_TO_ASCII ENDP

END START
