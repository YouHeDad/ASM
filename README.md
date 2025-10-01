Compile                                  
 1.  Clone project to your base C: dir - so that final structure is C:\ASM\TASM\
 2.  Open a terminal and cd to C:\ASM\TASM
 3.  Type 'c:\ASM\tasm\asm aslotsa' as your compile command
       *PS.  I can't get it to compile using relative paths)
       *PSS. 'aslotsa' is the .z80 source file without the extension.  yball is also included if you want a quick working sprite mover.
 4. Now you should have a .83 file and a .83p file that you can send to the VTI (I can only find an 83+ ROM, that's why it's cross-compatible)

Run
 1.  Send ion.8xg to your 83+ emu
 2.  Run ION - this will create 5 programs 
 3.  Send the .83xp file that you compiled to the emu
 4.  Run ION from the file named, 'A'

------------------------------------------------------------------------------
For some of the querks
  https://tutorials.eeems.ca/ASMin28Days/lesson/toc.html

Directory structure & files
  The pdfs in C:\ASM contain all the juice
  \ASM\vti\vti.exe is the 83+ emulator

Debugging
  \ASM\TI Education\TI-83 Plus Flash Debugger - This has an ultrafast emulator and memory tracing & debugging, etc, etc




