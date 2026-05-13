#!/bin/bash
set -euo pipefail

# Kiểm tra xem người dùng đã nhập tên module chưa
if [ $# -eq 0 ]; then
  echo "LỖI: Chưa nhập tên module cần test."
  echo "Sử dụng: $0 <Tên_Module>"
  echo "Ví dụ  : $0 ALU"
  exit 1
fi

TARGET_MODULE="$1"

# Cấu hình thư mục
RTL_DIR="${RTL_DIR:-src}"
NETLIST_DIR="${NETLIST_DIR:-netlist_unit}"
REPORT_DIR="${REPORT_DIR:-reports_unit}"
OUT_NETLIST="${NETLIST_DIR}/${TARGET_MODULE}_syn.v"

# Thư viện Standard Cell (Nếu có dùng cho ASIC)
LIBERTY="${LIBERTY:-}"
# Nếu dùng Liberty, Yosys LEC cần file mô phỏng Verilog của các cổng logic (NAND, NOR...)
STD_CELL_V="${STD_CELL_V:-}" 

mkdir -p "${NETLIST_DIR}" "${REPORT_DIR}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

run_with_log() {
  local step_name="$1"
  local log_file="$2"
  shift 2
  echo -n "Đang chạy ${step_name}... "
  if ! "$@" > "${log_file}" 2>&1; then
    echo "THẤT BẠI ❌"
    echo "Vui lòng xem chi tiết lỗi tại: ${log_file}"
    exit 1
  fi
  echo "THÀNH CÔNG ✅"
}

echo "====================================================="
echo "   UNIT TEST SYNTHESIS & LEC CHO MODULE: ${TARGET_MODULE}"
echo "====================================================="
echo "RTL_DIR    : ${RTL_DIR}"
echo "NETLIST    : ${OUT_NETLIST}"
if [[ -n "${LIBERTY}" ]]; then
  echo "LIBERTY    : ${LIBERTY}"
else
  echo "LIBERTY    : (Bỏ qua - Tổng hợp gate-level cơ bản của Yosys)"
fi
echo "====================================================="

if [[ ! -d "${RTL_DIR}" ]]; then
  echo "LỖI: Không tìm thấy thư mục RTL: ${RTL_DIR}"
  exit 1
fi

# ==========================================
# TẠO SCRIPT YOSYS SYNTHESIS TRONG BỘ NHỚ TẠM
# ==========================================
cat <<EOF > "${TMP_DIR}/synth_${TARGET_MODULE}.ys"
read_verilog -sv ${RTL_DIR}/*.v
hierarchy -check -top ${TARGET_MODULE}
proc
opt
fsm
opt
memory -nomap
memory_map
opt
techmap
opt
$(if [[ -n "${LIBERTY}" ]]; then echo "dfflibmap -liberty ${LIBERTY}"; echo "abc -liberty ${LIBERTY}"; fi)
clean -purge
write_verilog -noattr ${OUT_NETLIST}
EOF

# ==========================================
# TẠO SCRIPT YOSYS LEC TRONG BỘ NHỚ TẠM
# ==========================================
cat <<EOF > "${TMP_DIR}/lec_${TARGET_MODULE}.ys"
# 1. ĐỌC BẢN GỐC (GOLDEN)
read_verilog -sv ${RTL_DIR}/*.v
hierarchy -check -top ${TARGET_MODULE}
prep -top ${TARGET_MODULE}
memory_map                
async2sync
design -stash gold

# 2. ĐỌC BẢN TỔNG HỢP (GATE)
$(if [[ -n "${STD_CELL_V}" ]]; then echo "read_verilog -lib -sv ${STD_CELL_V}"; fi)
read_verilog -sv ${OUT_NETLIST}
hierarchy -check -top ${TARGET_MODULE}
prep -top ${TARGET_MODULE}
memory_map                
async2sync
design -stash gate

# 3. SO SÁNH (EQUIVALENCE CHECK)
design -copy-from gold -as gold ${TARGET_MODULE}
design -copy-from gate -as gate ${TARGET_MODULE}
equiv_make gold gate equiv
prep -top equiv

setundef -undriven -zero
equiv_simple
equiv_induct -seq 10  # Vì là module con nên giảm depth xuống cho nhanh
equiv_purge              
equiv_status -assert
EOF

echo
# 1. Chạy Tổng hợp
run_with_log "Synthesis (${TARGET_MODULE})" "${REPORT_DIR}/synth_${TARGET_MODULE}.log" yosys -s "${TMP_DIR}/synth_${TARGET_MODULE}.ys"

if [[ ! -f "${OUT_NETLIST}" ]]; then
  echo "LỖI: Synthesis không tạo ra được netlist: ${OUT_NETLIST}"
  exit 1
fi

# 2. Chạy LEC
run_with_log "Logic Equivalence Check (${TARGET_MODULE})" "${REPORT_DIR}/lec_${TARGET_MODULE}.log" yosys -s "${TMP_DIR}/lec_${TARGET_MODULE}.ys"

echo
echo "🎉 Hoàn tất kiểm tra module ${TARGET_MODULE}! Hai bản RTL và Netlist khớp nhau hoàn toàn."
echo "File Netlist lưu tại : ${OUT_NETLIST}"
echo "File Log lưu tại     : ${REPORT_DIR}/"