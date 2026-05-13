#!/bin/bash
set -euo pipefail

TOP="${TOP:-Top_module_pipeline_RISC_V_32I}"
RTL_DIR="${RTL_DIR:-src}"
NETLIST_DIR="${NETLIST_DIR:-netlist}"
REPORT_DIR="${REPORT_DIR:-reports}"
CONSTRAINTS="${CONSTRAINTS:-constraints/Top_module_pipeline_RISC_V_32I.sdc}"
OUT_NETLIST="${OUT_NETLIST:-${NETLIST_DIR}/${TOP}_syn.v}"
LIBERTY="${LIBERTY:-sky130_fd_sc_hd__tt_025C_1v80.lib}"

mkdir -p "${NETLIST_DIR}" "${REPORT_DIR}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

run_with_log() {
  local step_name="$1"
  local log_file="$2"
  shift 2
  if ! "$@" | tee "${log_file}"; then
    echo "ERROR: ${step_name} failed. See ${log_file}"
    exit 1
  fi
}

echo "====================================="
echo "Open-source RTL -> Netlist flow"
echo "TOP        : ${TOP}"
echo "RTL_DIR    : ${RTL_DIR}"
echo "NETLIST    : ${OUT_NETLIST}"
echo "CONSTRAINT : ${CONSTRAINTS}"
if [[ -n "${LIBERTY}" ]]; then
  echo "LIBERTY    : ${LIBERTY}"
else
  echo "LIBERTY    : (not set)"
fi
echo "====================================="

if [[ ! -d "${RTL_DIR}" ]]; then
  echo "ERROR: RTL directory not found: ${RTL_DIR}"
  exit 1
fi
if [[ ! -f "${CONSTRAINTS}" ]]; then
  echo "ERROR: constraints file not found: ${CONSTRAINTS}"
  exit 1
fi

echo
echo "[1/3] Synthesis (Yosys)"
if [[ -n "${LIBERTY}" ]]; then
  sed \
    -e "s|__TOP__|${TOP}|g" \
    -e "s|__OUT_NETLIST__|${OUT_NETLIST}|g" \
    -e "s|__LIBERTY__|${LIBERTY}|g" \
    scripts/synth_with_lib.ys > "${TMP_DIR}/synth_with_lib.ys"
  run_with_log "Synthesis" "${REPORT_DIR}/synth.log" yosys -s "${TMP_DIR}/synth_with_lib.ys"
else
  sed \
    -e "s|__TOP__|${TOP}|g" \
    -e "s|__OUT_NETLIST__|${OUT_NETLIST}|g" \
    scripts/synth.ys > "${TMP_DIR}/synth.ys"
  run_with_log "Synthesis" "${REPORT_DIR}/synth.log" yosys -s "${TMP_DIR}/synth.ys"
fi

if [[ ! -f "${OUT_NETLIST}" ]]; then
  echo "ERROR: synthesis did not generate netlist: ${OUT_NETLIST}"
  exit 1
fi

echo
echo "[2/3] RTL vs Netlist Equivalence (Yosys)"
sed \
  -e "s|__TOP__|${TOP}|g" \
  -e "s|__NETLIST__|${OUT_NETLIST}|g" \
  scripts/lec.ys > "${TMP_DIR}/lec.ys"
run_with_log "LEC" "${REPORT_DIR}/lec.log" yosys -s "${TMP_DIR}/lec.ys"

echo
echo "[3/3] Static Timing Analysis (OpenSTA)"
if [[ -z "${LIBERTY}" ]]; then
  echo "SKIP: STA requires LIBERTY."
  echo "      Re-run with: LIBERTY=/path/to/your.lib ./scripts/run_open_flow.sh"
else
  # TRUYỀN THAM SỐ QUA BIẾN MÔI TRƯỜNG
  export STA_TOP="${TOP}"
  export STA_LIBERTY="${LIBERTY}"
  export STA_NETLIST="${OUT_NETLIST}"
  export STA_SDC="${CONSTRAINTS}"
  export STA_REPORT_DIR="${REPORT_DIR}"

  # Chạy sta và chỉ trỏ vào file script tcl
  run_with_log "STA" "${REPORT_DIR}/sta.log" sta -exit scripts/run_sta.tcl
fi

echo
echo "Done. Check logs in ${REPORT_DIR}/ and netlist in ${NETLIST_DIR}/"