This simple graphical user interface (GUI) allows you to quickly set up a serial port for simple communication.  

There are two versions, Serial_GUI and Serial_GUI_noICT.  Serial_GUI requires the Instrument Control Toolbox because it calls the INSTRHWINFO function to check for all available serial ports and automatically populates the upper right-hand corner listbox.  Serial_GUI_noICT generates a list of serial ports (COM1 through COM12).  These ports may or may not be available.  Furthermore, there may be availabe ports not listed.

The port and baud rate can be specified, but only when disconnected.  If connected, disconnect the serial connection first, make the changes, and re-connect.

[Note: This example was created in MATLAB R2009b, but has been tested to work on releases back to R2007b.  For use with earlier versions, remove the try-catch statement (i.e. comment out the 'try' line, keep the commands in the try block, comment out the 'catch' line, the catch block, and the 'end' line.]