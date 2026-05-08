# Usage:
#   sta -exit \
#     -top <top_module> \
#     -liberty <liberty_file> \
#     -netlist <netlist_file> \
#     -sdc constraints/<file>.sdc \
#     -report_dir reports \
#     scripts/run_sta.tcl

if {![info exists top]} {
  puts "ERROR: missing -top <top_module>"
  exit 1
}
if {![info exists liberty]} {
  puts "ERROR: missing -liberty <liberty_file>"
  exit 1
}
if {![info exists netlist]} {
  puts "ERROR: missing -netlist <netlist_file>"
  exit 1
}
if {![info exists sdc]} {
  puts "ERROR: missing -sdc <constraints.sdc>"
  exit 1
}
if {![info exists report_dir]} {
  set report_dir "reports"
}

read_liberty $liberty
read_verilog $netlist
link_design $top
read_sdc $sdc

check_setup -verbose > "$report_dir/sta_check_setup.rpt"
report_checks -path_delay max -group_count 20 -digits 4 > "$report_dir/sta_setup.rpt"
report_checks -path_delay min -group_count 20 -digits 4 > "$report_dir/sta_hold.rpt"
report_tns > "$report_dir/sta_tns.rpt"
report_wns > "$report_dir/sta_wns.rpt"
report_clock_properties > "$report_dir/sta_clock.rpt"
report_design_area > "$report_dir/sta_area.rpt"

puts "STA reports generated in $report_dir"
