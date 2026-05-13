# Lấy thông số từ biến môi trường
set top        $::env(STA_TOP)
set liberty    $::env(STA_LIBERTY)
set netlist    $::env(STA_NETLIST)
set sdc        $::env(STA_SDC)
set report_dir $::env(STA_REPORT_DIR)

# Thực hiện quy trình STA
read_liberty $liberty
read_verilog $netlist
link_design $top
read_sdc $sdc

# Chỉ giữ lại các lệnh báo cáo thời gian chuẩn của OpenSTA
check_setup -verbose > "$report_dir/sta_check_setup.rpt"
report_checks -path_delay max -group_count 20 -digits 4 > "$report_dir/sta_setup.rpt"
report_checks -path_delay min -group_count 20 -digits 4 > "$report_dir/sta_hold.rpt"
report_tns > "$report_dir/sta_tns.rpt"
report_wns > "$report_dir/sta_wns.rpt"
report_clock_properties > "$report_dir/sta_clock.rpt"

puts "STA: Hoàn tất xuất báo cáo TIMING vào thư mục $report_dir"