<?php
require_once 'db.php';

$data = json_decode(file_get_contents('php://input'), true);
$username = $data['username'] ?? '';
$password = $data['password'] ?? '';

if ($username === '' || $password === '') {
    http_response_code(400);
    echo json_encode(['error' => 'Thiếu tài khoản hoặc mật khẩu']);
    exit;
}

$stmt = $mysqli->prepare(
    "SELECT id, username, role, display_name FROM accounts WHERE username = ? AND password_hash = SHA2(?, 256)"
);
$stmt->bind_param('ss', $username, $password);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode([
        'id'          => (int)$row['id'],
        'username'    => $row['username'],
        'role'        => $row['role'],
        'displayName' => $row['display_name']
    ]);
} else {
    http_response_code(401);
    echo json_encode(['error' => 'Sai tài khoản hoặc mật khẩu']);
}

$stmt->close();
$mysqli->close();
