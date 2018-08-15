#!/bin/zsh 

export BOARD="zybo"

if [ "$BOARD" = "zybo" ]; then
    export XILINX_PART="xc7z020clg400-1"
    export XILINX_BOARD="digilentinc.com:zybo-z7-20:part0:1.0"
else
    echo "Board not supported!"
    exit
fi

echo "Selected board: $XILINX_BOARD"