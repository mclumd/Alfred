
#
# Makefile for simple message box demo (static and dll versions)
#

SYS = ix86

default: $(SYS)\fib.dll $(SYS)\fib.lib $(SYS)\fibs.lib popup.qof

all: $(SYS)\popup.exe $(SYS)\popups.exe

# Executable with DLL dependencies
$(SYS)\popup.exe: popup.qof $(SYS)\fib.lib
	qld -do $@ popup.qof

# Static executable with no DLL dependencies suitable for running under
# Microsoft Windows as well as Windows NT.
$(SYS)\popups.exe: popup.qof $(SYS)\fibs.lib
	qld -Sdo $@ popup.qof

popup.qof: popup.pl
	qpc -c popup.pl

$(SYS)\fibs.lib: $(SYS)\static\fib.obj
	lib -out:$@ $**

$(SYS)\static\fib.obj: fib.c
	cl -Fo$@ -c -ML $**

$(SYS)\fib.lib $(SYS)\fib.dll: $(SYS)\dll\fib.obj
	link -out:$(SYS)\fib.dll -dll -export:fib $**

$(SYS)\dll\fib.obj: fib.c
	cl -Fo$@ -c -MD $**

clean:
	del /s/f/q $(SYS)
