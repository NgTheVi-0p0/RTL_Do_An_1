#!/bin/bash
set -euo pipefail

# --- KHỞI TẠO CÁC BIẾN CỜ (FLAGS) ĐỂ KIỂM SOÁT CÁC BƯỚC ---
RUN_SYNTH=false
RUN_LEC=false
RUN_STA=false

# Hàm hướng dẫn cách dùng (Help)
usage() {
  echo "Cách sử dụng: $0 [tùy_chọn]"
  echo "Các tùy chọn:"
  echo "  -1, --synth     Chỉ chạy Bước 1: Synthesis (Yosys)"
  echo "  -2, --lec       Chỉ chạy Bước 2: Equivalence Check (Yosys LEC)"
  echo "  -3, --sta       Chỉ chạy Bước 3: Static Timing Analysis (OpenSTA)"
  echo "  -h, --help      Hiển thị hướng dẫn này"
  echo ""
  echo "Ví dụ:"
  echo "  $0              Chạy toàn bộ luồng 3 bước (mặc định)"
  echo "  $0 -1 -2        Chỉ chạy bước Synthesis và LEC"
  echo "  $0 -3           Chỉ chạy duy nhất bước STA"
  exit 0
}

# --- PARSE THAM SỐ DÒNG LỆNH ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -1|--synth)
      RUN_SYNTH=true
      shift
      ;;
    -2|--lec)
      RUN_LEC=true
      shift
      ;;
    -3|--sta)
      RUN_STA=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "LỖI: Tùy chọn không hợp lệ: $1"
      usage
      ;;
  esac
done

# Nếu không truyền bất kỳ tham số nào, mặc định kích hoạt cả 3 bước
if [ "$RUN_SYNTH" = false ] && [ "$RUN_LEC" = false ] && [ "$RUN_STA" = false ]; then
  RUN_SYNTH=true
  RUN_LEC=true
  RUN_STA=true
fi

# --- CÁC ĐƯỜNG DẪN MẶC ĐỊNH (GIỮ NGUYÊN) ---
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

# ==============================================================================
# [BƯỚC 1/3] SYNTHESIS
# ==============================================================================
if [ "$RUN_SYNTH" = true ]; then
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
fi

# ==============================================================================
# [BƯỚC 2/3] LOGIC EQUIVALENCE CHECK (LEC)
# ==============================================================================
if [ "$RUN_LEC" = true ]; then
  echo
  echo "[2/3] RTL vs Netlist Equivalence (Yosys)"
  
  # Kiểm tra nhanh xem đã có file netlist để so sánh chưa trước khi chạy độc lập
  if [[ ! -f "${OUT_NETLIST}" ]]; then
    echo "ERROR: File Netlist để so sánh không tồn tại tại: ${OUT_NETLIST}"
    echo "       Bạn cần chạy bước 1 (-1) trước để sinh ra file Netlist."
    exit 1
  fi

  sed \
    -e "s|__TOP__|${TOP}|g" \
    -e "s|__NETLIST__|${OUT_NETLIST}|g" \
    scripts/lec.ys > "${TMP_DIR}/lec.ys"
  run_with_log "LEC" "${REPORT_DIR}/lec.log" yosys -s "${TMP_DIR}/lec.ys"
fi

# ==============================================================================
# [BƯỚC 3/3] STATIC TIMING ANALYSIS (STA)
# ==============================================================================
if [ "$RUN_STA" = true ]; then
  echo
  echo "[3/3] Static Timing Analysis (OpenSTA)"
  
  # Kiểm tra nhanh xem đã có file netlist để phân tích timing chưa trước khi chạy độc lập
  if [[ ! -f "${OUT_NETLIST}" ]]; then
    echo "ERROR: File Netlist để chạy STA không tồn tại tại: ${OUT_NETLIST}"
    echo "       Bạn cần chạy bước 1 (-1) trước để sinh ra file Netlist."
    exit 1
  fi

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
fi

echo
echo "Done. Check logs in ${REPORT_DIR}/"