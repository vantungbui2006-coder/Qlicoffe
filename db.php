<?php
// ============================================================
// Kết nối database dùng mysqli — mọi file api/*.php đều require file này
// ============================================================
header('Content-Type: application/json; charset=utf-8');

// Chặn cache tuyệt đối — nếu không có các header này, trình duyệt có thể
// tự lưu lại response cũ và không gọi lại server, khiến UI hiện dữ liệu
// cũ dù database đã đổi (đây chính là lỗi gây hiện sai trạng thái đơn).
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');

// Nếu XAMPP đặt mật khẩu root khác rỗng, sửa tham số thứ 3 bên dưới
$mysqli = new mysqli('localhost', 'root', '', 'coffee_order');
$mysqli->set_charset('utf8mb4');

if ($mysqli->connect_error) {
    http_response_code(500);
    echo json_encode(['error' => 'Kết nối database thất bại: ' . $mysqli->connect_error]);
    exit;
}
