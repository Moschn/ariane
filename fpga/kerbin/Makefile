PROJECT:=kerbin

all:
	vivado -mode batch -source tcl/run.tcl
gui:
	vivado -mode gui -source tcl/run.tcl &
interactive:
	vivado -mode tcl -source tcl/run.tcl

clean:
	rm -rf ${PROJECT}.*
	rm -rf component.xml
	rm -rf vivado*.jou
	rm -rf vivado*.log
	rm -rf vivado*.str
	rm -rf xgui
	rm -rf .Xil

