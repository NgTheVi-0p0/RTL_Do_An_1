# Thiết kế bộ vi xử lý RISC-V RV32I hỗ trợ Branch Prediction

Dự án thực hiện quy trình thiết kế từ RTL đến GDSII (ASIC Flow) sử dụng công cụ mã nguồn mở (OpenLane).

## 🚀 Tiến độ dự án (Progress)

### 1. Khối RTL (Verilog Design)
- [x] ALU (Arithmetic Logic Unit)
- [x] Control Unit
- [x] Register File
- [x] Datapath Integration
- [ ] Branch Prediction (Gshare Algorithm) - *Đang thực hiện*
- [ ] Hazard Unit (Forwarding/Stalling)

### 2. Kiểm tra & Mô phỏng (Simulation)
- [x] Kiểm tra 37 lệnh cơ bản (R, I, S, U type)
- [ ] Kiểm tra Branch/Jump instructions
- [ ] Gate-level Simulation (GLS)

### 3. Thiết kế vật lý (Physical Design - OpenLane)
- [x] Logic Synthesis
- [ ] Floorplan & Placement
- [ ] CTS & Routing
- [ ] Sign-off (DRC/LVS check)

## 🛠 Công cụ sử dụng (Tools)
*   **Editor:** VS Code (WSL2 Ubuntu 22.04)
*   **Simulation:** Icarus Verilog + GTKWave
*   **Synthesis:** Yosys
*   **Backend:** OpenLane (Docker)
