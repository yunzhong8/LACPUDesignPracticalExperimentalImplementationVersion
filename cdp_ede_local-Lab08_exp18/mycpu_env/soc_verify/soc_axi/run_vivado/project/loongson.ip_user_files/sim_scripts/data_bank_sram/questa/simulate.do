onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib data_bank_sram_opt

do {wave.do}

view wave
view structure
view signals

do {data_bank_sram.udo}

run -all

quit -force