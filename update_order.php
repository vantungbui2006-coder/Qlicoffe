<?php
require_once 'db.php';

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['id'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Thiếu id đơn hàng']);
    exit;
}

$id = $data['id'];
$fields = [];
$types = '';
$values = [];

if (array_key_exists('status', $data)) {
    $fields[] = 'status = ?';
    $types .= 's';
    $values[] = $data['status'];
}
if (array_key_exists('paymentMethod', $data)) {
    $fields[] = 'payment_method = ?';
    $types .= 's';
    $values[] = $data['paymentMethod'];
}
if (array_key_exists('note', $data)) {
    $fields[] = 'note = ?';
    $types .= 's';
    $values[] = $data['note'];
}
// Gán ai xử lý đơn (thu ngân hoặc pha chế), dựa theo người đang đăng nhập
if (!empty($data['actorId']) && !empty($data['role'])) {
    if ($data['role'] === 'cashier') {
        $fields[] = 'cashier_id = ?';
        $types .= 'i';
        $values[] = (int)$data['actorId'];
    } elseif ($data['role'] === 'barista') {
        $fields[] = 'barista_id = ?';
        $types .= 'i';
        $values[] = (int)$data['actorId'];
    }
}

if (empty($fields)) {
    echo json_encode(['message' => 'Không có gì để cập nhật']);
    exit;
}

$types .= 's';
$values[] = $id;

$sql = "UPDATE orders SET " . implode(', ', $fields) . " WHERE id = ?";
$stmt = $mysqli->prepare($sql);

if ($stmt === false) {
    http_response_code(500);
    echo json_encode(['error' => $mysqli->error]);
    exit;
}

$stmt->bind_param($types, ...$values);

if ($stmt->execute()) {
    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['error' => $stmt->error]);
}

$stmt->close();
$mysqli->close();
