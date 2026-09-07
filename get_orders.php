<?php
require_once 'db.php';

$orders = [];

$sql = "SELECT o.id, o.customer_name, o.note, o.status, o.payment_method, o.created_at,
               ct.table_name
        FROM orders o
        JOIN coffee_tables ct ON ct.id = o.table_id
        ORDER BY o.created_at DESC";
$result = $mysqli->query($sql);

if ($result === false) {
    http_response_code(500);
    echo json_encode(['error' => $mysqli->error]);
    exit;
}

while ($row = $result->fetch_assoc()) {
    $orderId = $row['id'];

    $itemsStmt = $mysqli->prepare(
        "SELECT mi.name, oi.quantity AS qty, oi.unit_price AS price
         FROM order_items oi
         JOIN menu_items mi ON mi.id = oi.menu_item_id
         WHERE oi.order_id = ?"
    );
    $itemsStmt->bind_param('s', $orderId);
    $itemsStmt->execute();
    $itemsResult = $itemsStmt->get_result();

    $items = [];
    while ($item = $itemsResult->fetch_assoc()) {
        $items[] = [
            'name'  => $item['name'],
            'qty'   => (int)$item['qty'],
            'price' => (float)$item['price']
        ];
    }
    $itemsStmt->close();

    $orders[] = [
        'id'            => $row['id'],
        'table'         => $row['table_name'],
        'customer'      => $row['customer_name'],
        'items'         => $items,
        'note'          => $row['note'],
        'status'        => $row['status'],
        'paymentMethod' => $row['payment_method'],
        'createdAt'     => strtotime($row['created_at']) * 1000
    ];
}

echo json_encode($orders);
$mysqli->close();
