// ============================================================
// M-QR Coffee Order — Shared Mock Backend (localStorage)
// ------------------------------------------------------------
// File này ĐANG giả lập backend. Khi có API thật (PHP/Node...),
// chỉ cần thay nội dung bên trong getOrders() / updateOrder() /
// login() bằng fetch() gọi API — GIỮ NGUYÊN tên hàm & shape dữ
// liệu trả về để cashier.html / barista.html không cần sửa gì.
// ============================================================

const STORAGE_KEY = 'mqr_orders';
const SESSION_KEY = 'mqr_session';

// Tài khoản demo — sau này thay bằng bảng users thật trong DB
const ACCOUNTS = [
  { username: 'thungan', password: '123456', role: 'cashier', displayName: 'Thu Ngân' },
  { username: 'phache',  password: '123456', role: 'barista', displayName: 'Pha Chế' }
];

const STATUS = {
  CHO_XAC_NHAN:   'cho_xac_nhan',
  DA_XAC_NHAN:    'da_xac_nhan',
  CHO_THANH_TOAN: 'cho_thanh_toan',
  DA_THANH_TOAN:  'da_thanh_toan',
  CHUYEN_BEP:     'chuyen_bep',
  DANG_PHA_CHE:   'dang_pha_che',
  HOAN_THANH:     'hoan_thanh'
};

const STATUS_LABEL = {
  [STATUS.CHO_XAC_NHAN]:   'Chờ xác nhận',
  [STATUS.DA_XAC_NHAN]:    'Đã xác nhận',
  [STATUS.CHO_THANH_TOAN]: 'Chờ thanh toán',
  [STATUS.DA_THANH_TOAN]:  'Đã thanh toán',
  [STATUS.CHUYEN_BEP]:     'Chuyển bếp',
  [STATUS.DANG_PHA_CHE]:   'Đang pha chế',
  [STATUS.HOAN_THANH]:     'Hoàn thành'
};

// Thứ tự luồng đơn hàng — dùng để vẽ progress bar
const STATUS_FLOW = [
  STATUS.CHO_XAC_NHAN, STATUS.DA_XAC_NHAN, STATUS.CHO_THANH_TOAN,
  STATUS.DA_THANH_TOAN, STATUS.CHUYEN_BEP, STATUS.DANG_PHA_CHE, STATUS.HOAN_THANH
];

function seedOrders() {
  return [
    { id: 'DH001', table: 'Bàn 03', customer: 'Nguyễn Văn A',
      items: [{ name: 'Trà đào', qty: 2, price: 32000 }, { name: 'Bạc xỉu', qty: 1, price: 28000 }, { name: 'Cà phê sữa đá', qty: 1, price: 29000 }],
      note: '', status: STATUS.CHO_XAC_NHAN, paymentMethod: null, createdAt: Date.now() - 5 * 60000 },
    { id: 'DH002', table: 'Bàn 05', customer: 'Trần Thị B',
      items: [{ name: 'Bạc xỉu', qty: 2, price: 28000 }, { name: 'Trà đào', qty: 1, price: 32000 }],
      note: 'Ít đá', status: STATUS.CHO_THANH_TOAN, paymentMethod: null, createdAt: Date.now() - 10 * 60000 },
    { id: 'DH003', table: 'Bàn 02', customer: 'Lê Văn C',
      items: [{ name: 'Matcha đá xay', qty: 1, price: 36000 }, { name: 'Cà phê sữa đá', qty: 2, price: 29000 }],
      note: '', status: STATUS.DA_THANH_TOAN, paymentMethod: 'Tiền mặt', createdAt: Date.now() - 15 * 60000 },
    { id: 'DH004', table: 'Bàn 07', customer: 'Phạm Thị D',
      items: [{ name: 'Socola đá xay', qty: 2, price: 36000 }, { name: 'Trà đào', qty: 2, price: 32000 }],
      note: 'Không đường', status: STATUS.CHUYEN_BEP, paymentMethod: 'QR Banking', createdAt: Date.now() - 20 * 60000 },
    { id: 'DH005', table: 'Bàn 01', customer: 'Hoàng Văn E',
      items: [{ name: 'Cà phê sữa đá', qty: 2, price: 29000 }, { name: 'Bạc xỉu', qty: 1, price: 28000 }],
      note: '', status: STATUS.CHO_XAC_NHAN, paymentMethod: null, createdAt: Date.now() - 2 * 60000 }
  ];
}

function getOrders() {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) {
    const seeded = seedOrders();
    localStorage.setItem(STORAGE_KEY, JSON.stringify(seeded));
    return seeded;
  }
  try { return JSON.parse(raw); } catch (e) { return seedOrders(); }
}

function saveOrders(orders) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(orders));
  // Báo cho tab hiện tại re-render + báo cho tab khác qua sự kiện 'storage'
  window.dispatchEvent(new CustomEvent('mqr:orders-changed'));
}

function getOrder(id) {
  return getOrders().find(o => o.id === id) || null;
}

function updateOrder(id, patch) {
  const orders = getOrders();
  const idx = orders.findIndex(o => o.id === id);
  if (idx === -1) return null;
  orders[idx] = { ...orders[idx], ...patch };
  saveOrders(orders);
  return orders[idx];
}

function orderTotal(order) {
  return order.items.reduce((sum, i) => sum + i.qty * i.price, 0);
}

function formatVND(n) {
  return n.toLocaleString('vi-VN') + 'đ';
}

function timeAgo(ts) {
  const d = new Date(ts);
  return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
}

// Lắng nghe thay đổi dữ liệu (cùng tab và khác tab) để tự refresh UI
function onOrdersChanged(callback) {
  window.addEventListener('mqr:orders-changed', callback);
  window.addEventListener('storage', (e) => { if (e.key === STORAGE_KEY) callback(); });
}

// ==== Auth theo role ====
function login(username, password) {
  const acc = ACCOUNTS.find(a => a.username === username && a.password === password);
  if (!acc) return null;
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(acc));
  return acc;
}

function getSession() {
  const raw = sessionStorage.getItem(SESSION_KEY);
  return raw ? JSON.parse(raw) : null;
}

function logout() {
  sessionStorage.removeItem(SESSION_KEY);
  window.location.href = 'login.html';
}

// Chặn truy cập sai role — gọi ở đầu mỗi trang cashier.html / barista.html
function requireRole(role) {
  const session = getSession();
  if (!session || session.role !== role) {
    window.location.href = 'login.html';
    return null;
  }
  return session;
}
