PROJECT:=xilinx_dcache_bank_tag_256x46

all:
	vivado -mode batch -source tcl/run.tcl
gui:
	vivado -mode gui -source tcl/run.tcl &

clean:
	rm -rf ${PROJECT}.*
	rm -rf component.xml
	rm -rf vivado*.jou
	rm -rf vivado*.log
	rm -rf vivado*.str
	rm -rf xgui
	rm -rf .Xil

