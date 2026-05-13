#!/bin/bash

# Kiểm tra xem Netlist đã có chưa
if [ ! -f "netlist/Top_module_pipeline_RISC_V_32I_syn.v" ]; then
    echo "❌ LỖI: Chưa có file Netlist! Hãy chạy ./run_backend.sh trước."
    exit 1
fi

echo "=========================================================="
echo "🏗️  BẮT ĐẦU THIẾT KẾ VẬT LÝ (PHYSICAL DESIGN) BẰNG OPENLANE"
echo "=========================================================="

# Đường dẫn tới thư mục cài đặt OpenLane của bạn
# Sửa lại nếu bạn cài OpenLane ở chỗ khác
OPENLANE_DIR="$HOME/OpenLane"

# Copy cấu hình vào thư mục của OpenLane để nó nhận dạng dự án
mkdir -p $OPENLANE_DIR/designs/RISCV_DO_AN
cp openlane_config/config.json $OPENLANE_DIR/designs/RISCV_DO_AN/
cp openlane_config/pin_order.cfg $OPENLANE_DIR/designs/RISCV_DO_AN/
cp -r netlist constraints $OPENLANE_DIR/designs/RISCV_DO_AN/

# Khởi chạy Docker và chạy Flow
cd $OPENLANE_DIR
make mount <<EOF
./flow.tcl -design RISCV_DO_AN
EOF

echo "=========================================================="
echo "✅ HOÀN TẤT THIẾT KẾ VẬT LÝ!"
echo "File GDSII (Bản vẽ Layout) nằm tại: $OPENLANE_DIR/designs/RISCV_DO_AN/runs/lần_chạy/results/final/gds/"
echo "Hãy mở bằng KLayout để xem thành quả."
echo "=========================================================="