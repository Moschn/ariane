#!/bin/zsh 

export BOARD="arty"

if [ "$BOARD" = "zybo" ]; then
    export XILINX_PART="xc7z020clg400-1"
    export XILINX_BOARD="digilentinc.com:zybo-z7-20:part0:1.0"
elif [ "$BOARD" = "arty" ]; then
    export XILINX_PART="xc7s50csga324-1"
    export XILINX_BOARD="digilentinc.com:arty-s7-50:part0:1.0"
else
    echo "Board not supported!"
    exit
fi

echo "Selected board: $XILINX_BOARD"