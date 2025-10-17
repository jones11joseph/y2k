# y2k
y2k Assembly code


How to use this code

    Assemble and link: Use an x86 assembler like TASM (tasm your_file.asm) and linker (tlink your_file.obj) to create a .COM executable.
    Run in DOS: Execute the .COM file in a DOS environment or emulator (like DOSBox).
    Output: The program will first display the current date retrieved from the BIOS, then update the date to October 16, 2025, and print a success message.
    To verify the change, you can run the program again, and it will retrieve the newly set date.

Note: Writing directly to CMOS like this requires careful handling of interrupts (CLI/STI).
A real BIOS would handle these operations in a more robust way to prevent corruption during updates.
For a desktop application, it is safer to use operating system APIs rather than accessing hardware directly.
