create_clock -period 83.00 clk_wb
create_clock -period 27.75 clk_usb

set_max_delay 40 -from [get_clocks {clk_usb}] -to [get_clocks {clk_wb}]
set_min_delay  5 -from [get_clocks {clk_usb}] -to [get_clocks {clk_wb}]

set_max_delay 40 -from [get_clocks {clk_wb}] -to [get_clocks {clk_usb}]
set_min_delay  5 -from [get_clocks {clk_wb}] -to [get_clocks {clk_usb}]
