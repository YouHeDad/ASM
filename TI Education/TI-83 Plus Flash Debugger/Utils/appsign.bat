@echo off
if "%1" == "" goto usage1
if "%2" == "" goto usage1
if "%TI83PLUSDIR%" == "" goto notdefined
if not exist %TI83PLUSDIR%\utils\sighead.bin goto notfound

REM Save a copy of the hex file.
copy %2 copyoapp.hex

REM Remove the 03 record type. Fillapp can't handle the 03 record. 
REM type %2 | find /v ":00000003FD" > delete03.hex
REM copy delete03.hex %2

REM Fill the hex file. 
%TI83PLUSDIR%\utils\fillapp %2

REM Create the signature (tempsig.bin)
%TI83PLUSDIR%\utils\rabsig %1 %2 tempsig.bin

REM Add the length to the signature
copy %TI83PLUSDIR%\utils\sighead.bin+tempsig.bin /B sig.bin /B

REM Convert the signature to hex
%TI83PLUSDIR%\utils\convert sig.bin tmpsig.hex

REM Add the hex signature to the application.
%TI83PLUSDIR%\utils\addhex tmpsig.hex %2

REM Create a copy with the .app extension
copy %2 *.app

REM Create the .8xk file with the Graphlink Header
%TI83PLUSDIR%\utils\glheader %2

REM Restore the original
copy copyoapp.hex %2

del copyoapp.hex
del delete03.hex
del tempsig.bin
del sig.bin
del tmpsig.hex
goto done
:usage1
echo °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
echo ° Usage:                                                                     °
echo °     appsign keyfile.key appfile.hex                                        °
echo °                                                                            °
echo ° Example:                                                                   °
echo °     appsign myfile.key  demo.hex                                           °
echo °                                                                            °
echo °     Note: Output will be written to demo.8xk.                               °
echo °                                                                            °
echo °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
goto done
:notfound
echo °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
echo ° Unable to find file - sighead.bin.                                         °
echo ° Make sure varialble TI83PLUSDIR is defined and points to the               °
echo ° install directory.                                                         °
echo °                                                                            °
echo °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
goto done
:notdefined
echo °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
echo ° Environment varialble TI83PLUSDIR is not defined.                          °
echo ° It should point to the install directory.                                  °
echo °                                                                            °
echo °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
:done
