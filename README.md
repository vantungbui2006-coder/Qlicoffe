# Module Thu Ngân + Pha Chế — M-QR Coffee Order

## 1. File trong gói này
```
mqr-cashier-barista/
├── mock-data.js   # lớp dữ liệu dùng chung (đang giả lập backend bằng localStorage)
├── login.html     # đăng nhập, phân role
├── cashier.html   # Dashboard + Danh sách đơn + Chi tiết/Thanh toán
└── barista.html   # Hàng đợi pha chế
```

## 2. Chạy thử ngay (không cần server)
Mở trực tiếp `login.html` bằng trình duyệt (double-click là được, vì toàn bộ chỉ là HTML/JS thuần).

**Tài khoản demo:**
| Vai trò | Username | Password |
|---|---|---|
| Thu ngân | `thungan` | `123456` |
| Pha chế | `phache` | `123456` |

> Lưu ý: nếu mở file bằng `file://`, một số trình duyệt chặn `localStorage` chia sẻ giữa các tab khác thư mục — nên tốt nhất chạy qua local server:
> ```bash
> cd mqr-cashier-barista
> python -m http.server 5500
> ```
> rồi mở `http://localhost:5500/login.html`.

## 3. Luồng trạng thái đơn hàng (đúng theo 2 ảnh phác thảo)
```
Chờ xác nhận → Đã xác nhận → Chờ thanh toán → Đã thanh toán → Chuyển bếp → Đang pha chế → Hoàn thành
   (khách đặt)      (thu ngân bấm "Xác nhận" → nhảy thẳng qua "Chờ thanh toán")
                                          (thu ngân chọn PTTT + "Hoàn tất thanh toán")
                                                                  (thu ngân bấm "Chuyển bếp")
                                                                              (pha chế bấm "Bắt đầu")
                                                                                          (pha chế bấm "Hoàn thành" → khách thấy "mời đến quầy nhận nước")
```
- Thu ngân **không thể** bấm "Thanh toán" khi đơn còn ở "Chờ xác nhận" (nút bị disable) — đúng yêu cầu đề.
- Sau khi thu ngân "Chuyển bếp", đơn **tự động** biến mất khỏi việc của thu ngân và xuất hiện ở `barista.html`.
- Pha chế **chỉ thấy bàn + món + ghi chú**, không thấy giá tiền/khách hàng — đúng yêu cầu "chỉ tập trung vào đơn cần làm".

## 4. Tích hợp vào repo `M-QR` hiện có
```bash
cd coffee-order          # repo bạn đã clone
git checkout -b feature/cashier-barista

mkdir -p cashier pha-che
cp mock-data.js cashier/mock-data.js
cp mock-data.js pha-che/mock-data.js
cp login.html cashier/login.html
cp cashier.html cashier/cashier.html
cp barista.html pha-che/barista.html

git add .
git commit -m "Them module Thu ngan + Pha che"
git push -u origin feature/cashier-barista
```
Tuỳ cấu trúc thư mục thật của repo (đặc biệt nếu trang khách hàng cũng dùng chung 1 file dữ liệu), bạn có thể đặt `mock-data.js` ở thư mục gốc và trỏ `<script src="../mock-data.js">` từ cả 3 module (khách hàng / thu ngân / pha chế) để **dùng chung đúng một nguồn dữ liệu** — quan trọng để 3 màn hình đồng bộ trạng thái đơn theo thời gian thực.

## 5. Khi nối với Backend thật (bạn làm phần backend)
Toàn bộ chỗ cần sửa nằm trong `mock-data.js`, không đụng vào `cashier.html` / `barista.html`:

| Hàm hiện tại | Khi có API thật |
|---|---|
| `getOrders()` | `return await fetch('/api/orders').then(r => r.json())` |
| `updateOrder(id, patch)` | `return await fetch('/api/orders/'+id, {method:'PATCH', body: JSON.stringify(patch)})` |
| `login(u, p)` | gọi API `/api/login`, lưu token thay vì lưu cả account vào sessionStorage |
| `onOrdersChanged()` | thay bằng polling (`setInterval` gọi lại `getOrders()`) hoặc WebSocket nếu backend hỗ trợ real-time |

Vì `cashier.html`/`barista.html` chỉ gọi các hàm này (không thao tác localStorage trực tiếp), việc thay backend không phải sửa giao diện.

## 6. Điểm cần lưu ý khi thuyết trình / báo cáo
- Đăng nhập đúng role: `requireRole('cashier')` và `requireRole('barista')` tự redirect về `login.html` nếu sai role hoặc chưa đăng nhập.
- Dữ liệu đơn mẫu (`seedOrders()` trong `mock-data.js`) tự sinh lần đầu — muốn reset về trạng thái ban đầu, xoá `localStorage` key `mqr_orders` trong DevTools (Application → Local Storage).
