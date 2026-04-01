# Thiết kế bộ vi xử lý RISC-V RV32I hỗ trợ Branch Prediction

Dự án thực hiện quy trình thiết kế từ RTL đến GDSII (ASIC Flow) sử dụng công cụ mã nguồn mở (OpenLane).

## 🚀 Tiến độ dự án (Progress)

### 1. Khối RTL (Verilog Design)
- [ ] ALU (Arithmetic Logic Unit)
- [ ] Control Unit
- [ ] Register File
- [ ] Datapath Integration
- [ ] Branch Prediction (Gshare Algorithm) - *Đang thực hiện*
- [ ] Hazard Unit (Forwarding/Stalling)

### 2. Kiểm tra & Mô phỏng (Simulation)
- [ ] Kiểm tra 37 lệnh cơ bản (R, I, S, U type)
- [ ] Kiểm tra Branch/Jump instructions
- [ ] Gate-level Simulation (GLS)

### 3. Thiết kế vật lý (Physical Design - OpenLane)
- [ ] Logic Synthesis
- [ ] Floorplan & Placement
- [ ] CTS & Routing
- [ ] Sign-off (DRC/LVS check)

## 🛠 Công cụ sử dụng (Tools)
*   **Editor:** VS Code (WSL2 Ubuntu 22.04)
*   **Simulation:** Icarus Verilog + GTKWave
*   **Synthesis:** Yosys
*   **Backend:** OpenLane (Docker)







```markdown
# 📘 Hướng dẫn sử dụng Git/GitHub cho Nhóm Đồ Án RTL

Tài liệu này hướng dẫn các thành viên trong nhóm cách lấy code về máy, cập nhật code mới và đẩy phần việc của mình lên GitHub dùng chung (`RTL_Do_An_1`).

---

## 🛠 PHẦN 1: Cài đặt ban đầu (Chỉ làm 1 lần duy nhất)

**Bước 0: Chấp nhận lời mời**
- Kiểm tra Email của bạn, tìm thư từ GitHub và nhấn **"Accept Invitation"** để tham gia vào dự án.

**Bước 1: Tải toàn bộ code về máy tính**
Mở Terminal (hoặc Terminal trong VS Code) và gõ lệnh:
```bash
git clone https://github.com/NgTheVi-0p0/RTL_Do_An_1.git
```

**Bước 2: Di chuyển vào thư mục dự án**
Sau khi tải xong, bạn phải di chuyển Terminal vào trong thư mục chứa code:
```bash
cd RTL_Do_An_1
```

**Bước 3: Định danh tài khoản cá nhân**
Chạy 2 lệnh sau (thay tên và email của bạn vào) để hệ thống biết ai là người đang viết đoạn code nào:
```bash
git config --global user.name "Tên Của Bạn"
git config --global user.email "email_cua_ban@gmail.com"
```

---

## ♻️ PHẦN 2: Quy trình code hằng ngày (Lấy và Đẩy code)

⚠️ **Quy tắc Vàng:** ĐỂ KHÔNG BỊ ĐÈ CODE HAY MẤT CODE CỦA NHAU, hãy làm đúng theo thứ tự sau mỗi khi bạn ngồi vào máy tính:

### Bước 1: LẤY CODE MỚI NHẤT VỀ MÁY (Bắt buộc làm đầu tiên)
Trước khi gõ bất kỳ dòng code nào, hãy lấy phần code mà các bạn khác vừa làm về máy để đồng bộ:
```bash
git pull
```

### Bước 2: BẮT ĐẦU LÀM PHẦN VIỆC CỦA MÌNH
- Mở VS Code, tạo hoặc chỉnh sửa các file `.v` của mình.
- *Lưu ý: Bạn được phân công làm khối nào thì chỉ sửa file của khối đó (VD: Bạn làm ALU thì chỉ sửa `alu.v`). Đừng sửa file của người khác để tránh bị đụng code.*

### Bước 3: ĐẨY CODE LÊN CHO CẢ NHÓM (Sau khi làm xong)
Sau khi bạn làm xong và code chạy không có lỗi, hãy đẩy lên GitHub bằng 3 lệnh liên tiếp sau:

**1. Gom tất cả các file vừa sửa lại:**
```bash
git add .
```

**2. Đóng gói và ghi chú lại bạn vừa làm gì (Ghi rõ ràng để nhóm dễ hiểu):**
```bash
git commit -m "Đã làm xong khối ALU và testbench ALU"
```

**3. Đẩy gói code đó lên kho chung trên GitHub:**
```bash
git push
```

---

## 🆘 PHẦN 3: Xử lý lỗi khi 2 người cùng đẩy code (Conflict)

Nếu lúc gõ lệnh `git push` mà Terminal báo lỗi màu đỏ (có chữ **rejected** hoặc **fetch first**):
- **Nguyên nhân:** Có một bạn khác trong nhóm đã `push` code lên trước bạn 1 bước. GitHub không cho bạn push đè lên code của người đó.
- **Cách giải quyết:**
  1. Gõ lệnh `git pull` để tải phần code của bạn kia về ghép với code của mình.
  2. Nếu VS Code hiện màu xanh/vàng báo **Conflict (Xung đột)**, hãy xem kỹ dòng code đó, chọn "Accept Current Change" (Giữ code của mình) hoặc "Accept Incoming Change" (Giữ code của bạn kia).
  3. Sau khi sửa xong xung đột, lưu file lại và đẩy lên lại bằng chu kỳ 3 lệnh:
     ```bash
     git add .
     git commit -m "Sửa lỗi xung đột code"
     git push
     ```
```
