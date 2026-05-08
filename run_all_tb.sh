#!/bin/bash
set -u
cd "$(dirname "$0")"
mkdir -p mophong_vcd
mkdir -p reports netlist

echo "Running all testbenches one-by-one..."

mapfile -t TB_FILES < <(printf '%s\n' testbench/*_tb.v | sort)

if [[ ${#TB_FILES[@]} -eq 0 ]]; then
  echo "No testbench files found in testbench/*_tb.v"
  exit 1
fi

run_tb() {
  local tbfile="$1"
  local tbname
  tbname="$(basename "${tbfile}" .v)"
  local out="/tmp/${tbname}.out"

  printf '\n=== %s ===\n' "${tbname}"

  if iverilog -g2012 -Wall -s "${tbname}" -o "${out}" "${tbfile}" src/*.v; then
    if vvp "${out}"; then
      echo "[PASS] ${tbname}"
      return 0
    else
      echo "[FAIL] ${tbname} (simulation error)"
      return 1
    fi
  else
    echo "[FAIL] ${tbname} (compile error)"
    return 1
  fi
}

pass_count=0
fail_count=0

for tbfile in "${TB_FILES[@]}"; do
  if run_tb "${tbfile}"; then
    pass_count=$((pass_count + 1))
  else
    fail_count=$((fail_count + 1))
  fi
done

printf '\n=====================================\n'
echo "Completed. PASS=${pass_count}, FAIL=${fail_count}"
echo "====================================="

if [[ ${fail_count} -ne 0 ]]; then
  exit 1
fi

echo
echo "RTL testbenches passed."

if [[ "${1:-}" == "--with-flow" ]]; then
  echo "Running open-source synthesis/LEC/STA flow..."
  bash ./scripts/run_open_flow.sh
fi
