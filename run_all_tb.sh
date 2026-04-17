#!/bin/bash
set -e
cd "$(dirname "$0")"
mkdir -p mophong_vcd

echo "Running all testbenches one-by-one..."

run_tb() {
  local tbname="$1"
  local srcname="$2"
  local out="/tmp/${tbname}.out"
  echo "\n=== $tbname ==="
  if [[ "${srcname}" == "all" ]]; then
    iverilog -g2012 -Wall -o "${out}" "testbench/${tbname}.v" src/*.v
  else
    iverilog -g2012 -Wall -o "${out}" "testbench/${tbname}.v" "src/${srcname}.v"
  fi
  vvp "${out}"
}

run_tb ALU_tb ALU
run_tb Program_Counter_tb Program_Counter
run_tb Register_File_tb Register_File
run_tb control_unit_tb control_unit
run_tb data_memory_tb data_memory
run_tb instruction_memory_tb instruction_memory
run_tb imm_extend_tb imm_extend
run_tb Top_Single_Cycle_tb all

echo "All testbenches completed."
