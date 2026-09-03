-- ============================================================
-- COFFEE ORDER - Database Schema (MySQL / XAMPP)
-- Khớp đúng cấu trúc dữ liệu đang dùng trong mock-data.js
-- Import: phpMyAdmin -> tab Import -> chọn file này -> Go
-- Hoặc: mysql -u root -p < schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS coffee_order CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE coffee_order;

-- Dọn sạch trước khi tạo lại (giúp import lại nhiều lần không bị lỗi "already exists")
DROP VIEW  IF EXISTS v_order_totals;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS menu_items;
DROP TABLE IF EXISTS coffee_tables;
DROP TABLE IF EXISTS accounts;

-- ---------- 1. Tài khoản đăng nhập (Thu ngân / Pha chế) ----------
CREATE TABLE accounts (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('cashier','barista') NOT NULL,
  display_name  VARCHAR(100) NOT NULL,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- 2. Bàn ----------
CREATE TABLE coffee_tables (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  table_name  VARCHAR(20) NOT NULL UNIQUE,
  capacity    INT NOT NULL DEFAULT 4,                          -- sức chứa (số khách/bàn)
  status      ENUM('trong','dang_su_dung') NOT NULL DEFAULT 'trong'  -- trạng thái bàn hiện tại
) ENGINE=InnoDB;

-- ---------- 3. Thực đơn ----------
CREATE TABLE menu_items (
  id      INT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(100) NOT NULL,
  price   DECIMAL(10,0) NOT NULL,
  active  TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- ---------- 4. Đơn hàng ----------
-- status đi đúng 7 trạng thái trong STATUS_FLOW của mock-data.js
CREATE TABLE orders (
  id              VARCHAR(10) PRIMARY KEY,          -- 'DH001', 'DH002' ...
  table_id        INT NOT NULL,
  customer_name   VARCHAR(100) NOT NULL,
  note            VARCHAR(255) DEFAULT NULL,
  status          ENUM(
                    'cho_xac_nhan','da_xac_nhan','cho_thanh_toan',
                    'da_thanh_toan','chuyen_bep','dang_pha_che','hoan_thanh'
                  ) NOT NULL DEFAULT 'cho_xac_nhan',
  payment_method  VARCHAR(30) DEFAULT NULL,          -- 'Tiền mặt' | 'QR Banking' | 'MoMo' | 'VNPay'
  cashier_id      INT DEFAULT NULL,                  -- thu ngân nào xác nhận/thanh toán
  barista_id      INT DEFAULT NULL,                  -- pha chế nào xử lý
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_table   FOREIGN KEY (table_id)   REFERENCES coffee_tables(id),
  CONSTRAINT fk_orders_cashier FOREIGN KEY (cashier_id) REFERENCES accounts(id),
  CONSTRAINT fk_orders_barista FOREIGN KEY (barista_id) REFERENCES accounts(id)
) ENGINE=InnoDB;

-- ---------- 5. Chi tiết đơn hàng (items[] trong mock-data.js) ----------
CREATE TABLE order_items (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  order_id      VARCHAR(10) NOT NULL,
  menu_item_id  INT NOT NULL,
  quantity      INT NOT NULL DEFAULT 1,
  unit_price    DECIMAL(10,0) NOT NULL,   -- snapshot giá tại thời điểm đặt (tránh lệch khi menu đổi giá)
  CONSTRAINT fk_items_order FOREIGN KEY (order_id)     REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_items_menu  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id)
) ENGINE=InnoDB;

-- ============================================================
-- TRIGGER: tự động cập nhật trạng thái bàn (coffee_tables.status)
-- theo trạng thái đơn hàng — không cần sửa code PHP/JS phía trên.
-- Đặt TRƯỚC phần seed data để áp dụng ngay cho cả dữ liệu mẫu.
--
-- Lưu ý: viết dạng 1 CÂU LỆNH DUY NHẤT (không BEGIN...END), nên
-- KHÔNG cần DELIMITER — dán thẳng vào ô SQL của phpMyAdmin vẫn
-- chạy đúng, không bị cắt câu lệnh giữa chừng.
-- ============================================================
DROP TRIGGER IF EXISTS trg_order_insert_set_table_busy;
DROP TRIGGER IF EXISTS trg_order_update_set_table_free;

-- Có đơn mới tại bàn nào -> bàn đó chuyển "đang sử dụng"
CREATE TRIGGER trg_order_insert_set_table_busy
AFTER INSERT ON orders
FOR EACH ROW
UPDATE coffee_tables SET status = 'dang_su_dung' WHERE id = NEW.table_id;

-- Đơn chuyển sang "hoàn thành" (và trước đó chưa hoàn thành) -> bàn đó chuyển lại "trống"
-- Điều kiện IF được thay bằng điều kiện ngay trong WHERE, nên chỉ update khi đúng,
-- không khớp thì UPDATE này chỉ đơn giản ảnh hưởng 0 dòng (không lỗi).
CREATE TRIGGER trg_order_update_set_table_free
AFTER UPDATE ON orders
FOR EACH ROW
UPDATE coffee_tables
SET status = 'trong'
WHERE id = NEW.table_id
  AND NEW.status = 'hoan_thanh'
  AND OLD.status <> 'hoan_thanh';

-- ============================================================
-- SEED DATA - khớp 100% với seedOrders() trong mock-data.js
-- ============================================================

INSERT INTO accounts (username, password_hash, role, display_name) VALUES
('thungan', SHA2('123456', 256), 'cashier', 'Thu Ngân'),
('phache',  SHA2('123456', 256), 'barista', 'Pha Chế');

INSERT INTO coffee_tables (table_name, capacity) VALUES
('Bàn 01', 2),('Bàn 02', 4),('Bàn 03', 4),('Bàn 05', 6),('Bàn 07', 2);

INSERT INTO menu_items (name, price) VALUES
('Trà đào', 32000),
('Bạc xỉu', 28000),
('Cà phê sữa đá', 29000),
('Matcha đá xay', 36000),
('Socola đá xay', 36000);

-- Lưu ý: dùng table_id dạng số cố định (không dùng subquery SELECT trên
-- coffee_tables) — vì nếu subquery đọc coffee_tables ngay trong câu INSERT
-- này, trigger AFTER INSERT bên dưới sẽ bị MySQL chặn khi cố ghi vào chính
-- bảng coffee_tables đó (lỗi 1442: "already used by statement which invoked
-- this trigger"). ID khớp đúng thứ tự đã insert ở trên:
-- 1=Bàn 01, 2=Bàn 02, 3=Bàn 03, 4=Bàn 05, 5=Bàn 07
INSERT INTO orders (id, table_id, customer_name, note, status, payment_method, created_at) VALUES
('DH001', 3, 'Nguyễn Văn A', NULL,          'cho_xac_nhan',   NULL,          NOW() - INTERVAL 5  MINUTE),
('DH002', 4, 'Trần Thị B',   'Ít đá',        'cho_thanh_toan', NULL,          NOW() - INTERVAL 10 MINUTE),
('DH003', 2, 'Lê Văn C',     NULL,          'da_thanh_toan',  'Tiền mặt',    NOW() - INTERVAL 15 MINUTE),
('DH004', 5, 'Phạm Thị D',   'Không đường', 'chuyen_bep',     'QR Banking',  NOW() - INTERVAL 20 MINUTE),
('DH005', 1, 'Hoàng Văn E',  NULL,          'cho_xac_nhan',   NULL,          NOW() - INTERVAL 2  MINUTE);

INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price) VALUES
('DH001', (SELECT id FROM menu_items WHERE name='Trà đào'),         2, 32000),
('DH001', (SELECT id FROM menu_items WHERE name='Bạc xỉu'),         1, 28000),
('DH001', (SELECT id FROM menu_items WHERE name='Cà phê sữa đá'),   1, 29000),

('DH002', (SELECT id FROM menu_items WHERE name='Bạc xỉu'),         2, 28000),
('DH002', (SELECT id FROM menu_items WHERE name='Trà đào'),         1, 32000),

('DH003', (SELECT id FROM menu_items WHERE name='Matcha đá xay'),   1, 36000),
('DH003', (SELECT id FROM menu_items WHERE name='Cà phê sữa đá'),   2, 29000),

('DH004', (SELECT id FROM menu_items WHERE name='Socola đá xay'),   2, 36000),
('DH004', (SELECT id FROM menu_items WHERE name='Trà đào'),         2, 32000),

('DH005', (SELECT id FROM menu_items WHERE name='Cà phê sữa đá'),   2, 29000),
('DH005', (SELECT id FROM menu_items WHERE name='Bạc xỉu'),         1, 28000);

-- ============================================================
-- View tiện dùng: tổng tiền mỗi đơn (thay cho orderTotal() phía JS)
-- ============================================================
CREATE VIEW v_order_totals AS
SELECT o.id AS order_id, o.status, SUM(oi.quantity * oi.unit_price) AS total_amount
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, o.status;
