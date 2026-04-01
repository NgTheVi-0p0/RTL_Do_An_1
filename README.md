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









***

```markdown
# 📘 Hướng dẫn sử dụng Git/GitHub cho Nhóm Đồ Án RTL

Tài liệu này hướng dẫn các thành viên trong nhóm cách lấy code về máy, cập nhật code mới và đẩy phần việc của mình lên GitHub dùng chung (`RTL_Do_An_1`).

---

## 🛠 PHẦN 1: Cài đặt ban đầu (Chỉ làm 1 lần duy nhất)

**Bước 0: Chấp nhận lời mời**
- Kiểm tra Email của bạn, tìm thư từ GitHub và nhấn **"Accept Invitation"** để tham gia vào dự án.

**Bước 1: Tải toàn bộ code về máy tính (Clone code)**
Mở Terminal (hoặc Terminal trong VS Code) và gõ lệnh:
```bash
git clone https://github.com/NgTheVi-0p0/RTL_Do_An_1.git
```

**Bước 2: Di chuyển vào thư mục dự án vừa tải về**
```bash
cd RTL_Do_An_1
```

**Bước 3: Định danh tài khoản (Để nhóm biết ai là người viết đoạn code nào)**
Gõ 2 lệnh sau (Nhớ thay thông tin của bạn vào trong ngoặc kép):
```bash
git config --global user.name "Tên Của Bạn"
git config --global user.email "email_cua_ban@gmail.com"
```
*(Xong Phần 1! Máy tính của bạn đã kết nối thành công với kho code chung của nhóm).*

---

## ♻️ PHẦN 2: Quy trình làm việc HẰNG NGÀY (Cùng lấy và đẩy code)

Đây là quy trình **BẮT BUỘC** mỗi khi bạn ngồi vào máy tính để viết code. Việc này giúp tránh làm mất code của người khác.

### 👉 BƯỚC 1: LẤY CODE MỚI NHẤT VỀ (Pull)
**Tuyệt đối phải làm bước này đầu tiên** trước khi gõ bất kỳ dòng code nào. Lệnh này giúp bạn tải phần code mà các bạn khác vừa làm xong về máy mình để đồng bộ:
```bash
git pull
```
*(Nếu Terminal hiện dòng `Already up to date.` nghĩa là code trên máy bạn đang là mới nhất, không có ai thay đổi gì).*

### 👉 BƯỚC 2: Bắt đầu viết code của bạn
- Mở VS Code, sửa file, tạo file `.v` mới, chạy mô phỏng...
- **Nguyên tắc "Vàng":** Phân chia rõ ràng việc ai nấy làm. Hạn chế tối đa việc 2 người cùng mở 1 file (ví dụ `datapath.v`) ra sửa cùng lúc để tránh xung đột.

### 👉 BƯỚC 3: ĐẨY CODE LÊN GITHUB (Push)
Sau khi bạn code xong, chạy thử không có lỗi và muốn gửi lên cho cả nhóm dùng, hãy gõ lần lượt 3 lệnh sau:

**1. Đưa tất cả các file vừa sửa vào danh sách chuẩn bị gửi:**
```bash
git add .
```
*(Lưu ý: Có dấu chấm `.` ở cuối lệnh, nghĩa là chọn TẤT CẢ các file).*

**2. Ghi chú lại bạn vừa làm gì:** (Ghi chú rõ ràng để các bạn khác đọc còn hiểu)
```bash
git commit -m "Hoàn thành code khối ALU và viết xong file testbench"
```

**3. Đẩy code lên kho chung:**
```bash
git push
```
*(Lưu ý: Lần đẩy code đầu tiên, VS Code có thể sẽ bật lên một bảng thông báo yêu cầu đăng nhập GitHub. Bạn cứ bấm `Allow` hoặc `Sign in with Browser` để trình duyệt tự động xác thực là xong).*

---

## ⚠️ PHẦN 3: Xử lý khi bị lỗi (Conflict / Bị từ chối đẩy code)

**Tình huống:** Bạn gõ `git push` nhưng Terminal hiện một nùi chữ đỏ báo lỗi **"rejected"** hoặc **"fetch first"**.

- **Nguyên nhân:** Có một bạn khác trong nhóm đã `push` code lên trước bạn vài phút. Lúc này code trên GitHub đang mới hơn code trong máy bạn. Git khóa không cho bạn push đè lên để bảo vệ code của bạn kia.
- **Cách giải quyết (Chỉ cần làm đúng 3 bước):**
  
  1. Gõ lệnh tải code của bạn kia về ghép với code của mình:
     ```bash
     git pull
     ```
  2. Nếu VS Code hiện lên các dòng code có màu sắc lạ (Xanh lá/Xanh dương) báo hiệu **Conflict (Xung đột)**:
     - Đừng hoảng! Hãy nhìn vào đoạn code đó, VS Code sẽ hiện các nút bấm hỏi bạn muốn giữ lại code của bạn (Accept Current Change), hay giữ code của bạn kia (Accept Incoming Change), hay giữ cả hai.
     - Chọn cái đúng, chỉnh sửa lại cho hoàn chỉnh rồi Bấm Lưu file (`Ctrl + S`).
  3. Gõ lại chu kỳ đẩy code ban đầu:
     ```bash
     git add .
     git commit -m "Fix conflict code với bạn A"
     git push
     ```

---
### 💡 Mẹo nhỏ (Dùng giao diện VS Code thay cho gõ lệnh)
Nếu bạn lười gõ lệnh, hãy nhìn sang **Cột bên trái của VS Code (Biểu tượng nhánh cây - Source Control)**:
1. Bấm dấu `+` (Tương đương `git add .`).
2. Gõ chữ vào ô Message và bấm nút **Commit** (Tương đương `git commit -m "..."`).
3. Bấm nút **Sync Changes** (Tương đương gộp cả `git pull` và `git push` lại làm một).
```
