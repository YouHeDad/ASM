TachyonLink linking routines v1.0

Released: March 19, 2003
By Michael Vincent (michael@detachedsolutions.com)



FILES INCLUDED IN THIS ZIP
==========================

SEND.8XP - Demo sending program
RECEIVE.8XP - Demo receiving program
routines.asm - The TachyonLink routines
readme.txt - This file


THE LINK ROUTINES
==================

routines.asm contains the TachyonLink routines. There are a few things worth noting. One, the current routines will wait indefinitely to receive/send a byte. If you wish to add timeouts, then look at the loops of TachyonLink_Send_Wait and TachyonLink_Receive_Wait.

Also, the calculators must be of a similar link speed, the sending calculator can't be more than 30% or so faster than the receiving. Thus, two 83+s link at 6 MHz, and two SEs link at 6 or 15 MHz, but a SE and 83+ can link only if the SE is at 6 MHz. The routines should work on other calculators besides the 83+/SE, but will require minor modifications such as changing the link port number.

If you want to determine whether there is a byte being sent before calling the receive routine, you can use the same method as you do for the TI-OS routines, namely:

in a,(0)	;read link port status
and 3
cp 3		;if this sets NZ then there is a byte trying to be sent, so call the receive routine


USING THE DEMOS
===============

These are two remarkably boring programs, that just send 64000 bytes from one calculator to another. They run with Asm() from the homescreen, and start the receive one before you start send. They will exit upon finishing.


USING THE ROUTINES IN YOUR PROGRAMS
===================================

You can freely use the TachyonLink routines in any program, even one that is commercially sold. However, you must ackowledge me in the credits somewhere :). And if you're a wonderfully nice person with nothing better to do, you'll e-mail me and tell me what the practical use of these are, because I really can't think of one.


USELESS FACTS :)
================

Using a stopwatch, I timed my demo programs and obtained the following values: 4.3 KB/second at 6 MHz, and 10 KB/second at 15 MHz.