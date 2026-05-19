# API Documentation: pos semesta

## Konfigurasi Dasar
* **Base URL (pos perfex local)**: `http://flinkaja.com/`
* **Header Autentikasi**: Semua *request* (kecuali `pos_auth`) mewajibkan pengiriman header `authtoken`.

path: api/
---

## 1. Authentication

### `pos_auth`
* **Method**: `GET`
* **URL**: `{{base_url}}pos_auth?email&password`
* **Parameter (Query)**:
    * `email` (string)
    * `password` (string)

**Example Success Response:**
```json
{
    "status": true,
    "message": "Login successful",
    "base_url": "http://randiwahyudi.flinkaja.com/",
    "location": "1022",
    "staff": "RANDI",
    "email": "randhi.wahyudi@gmail.com"
}
```

---

## 2. Brands

### `pos_brands get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_brands`

**Example Success Response:**
```json
{
    "status": true,
    "brands": [
        {
            "id": "30",
            "name": "XIE XIE ICE CREAM",
            "commodity_group_code": "XII",
            "order": null,
            "display": "1",
            "note": null
        }
    ]
}
```

---

## 3. Categories

### `pos_categories get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_categories`

**Example Success Response:**
```json
{
    "status": true,
    "categories": [
        {
            "commodity_type_id": "7",
            "commondity_code": "XIE-CONSER",
            "commondity_name": "Cone Series",
            "brand": "XIE XIE ICE CREAM",
            "note": ""
        },
        {
            "commodity_type_id": "8",
            "commondity_code": "XIE-SUNSER",
            "commondity_name": "Sundae Series",
            "brand": "XIE XIE ICE CREAM",
            "note": ""
        }
    ]
}
```

### `pos_categories post`
* **Method**: `POST`
* **URL**: `{{base_url}}pos_categories`
* **Body (multipart-form)**:
    * `code`: string
    * `name`: string
    * `brand`: string
    * `note`: string

**Example Success Response:**
```json
{
  "status": true,
  "message": "Category added successfully.",
  "data": [
    {
      "commodity_type_id": "30",
      "commondity_code": "HIJKL",
      "commondity_name": "HIJKL category",
      "brand": "GHI TEST",
      "note": "test note"
    }
  ]
}
```

### `pos_categories put`
* **Method**: `PUT`
* **URL**: `{{base_url}}pos_categories?id=1`
* **Parameter (Query)**: `id`
* **Body (form-urlencoded)**: `code`, `name`, `brand`, `note`

**Example Success Response:**
```json
{
  "status": true,
  "message": "Category updated successfully.",
  "data": [
    {
      "commodity_type_id": "30",
      "commondity_code": "HIJKL",
      "commondity_name": "HIJKL category",
      "brand": "ABC TEST",
      "note": "update"
    }
  ]
}
```

### `pos_categories delete`
* **Method**: `DELETE`
* **URL**: `{{base_url}}pos_categories?id=1`
* **Parameter (Query)**: `id`

**Example Success Response:**
```json
{
  "status": true,
  "message": "Category deleted successfully."
}
```

---

## 4. Customers

### `pos_customer get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_customers`

**Example Success Response:**
```json
[
    {
        "id": "1",
        "nama": "Walk In",
        "no_hp": "",
        "alamat": "",
        "datecreated": "2026-04-11 16:09:16",
        "value_pts": "84"
    },
    {
        "id": "3",
        "nama": "test",
        "no_hp": "6255841280",
        "alamat": "res r",
        "datecreated": "2026-04-14 11:43:05",
        "value_pts": "18"
    }
]
```

### `pos_customer search_get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_customers/search/:keyword`

**Example Success Response:**
```json
[
    {
        "id": "1",
        "nama": "Walk In",
        "no_hp": "",
        "alamat": "",
        "datecreated": "2026-04-11 16:09:16",
        "value_pts": "84"
    }
]
```

### `pos_customer post`
* **Method**: `POST`
* **URL**: `{{base_url}}pos_customers`
* **Body (multipart-form)**: `id_pos`, `nama`, `no_hp`, `email`, `alamat`, `jenis_kel`, `tanggal_lahir`, `kategori_cust`

**Example Success Response:**
```json
{
    "status": true,
    "message": "Client add successful.",
    "data": {
        "id": "2",
        "nama": "Test API",
        "no_hp": "62857493759",
        "alamat": "Gudang Cemani",
        "datecreated": "2026-05-18 09:29:46",
        "value_pts": "0"
    }
}
```

### `pos_customer put`
* **Method**: `PUT`
* **URL**: `{{base_url}}pos_customers/:id`
* **Body (json)**:
```json
{
  "nama": "Test Customer",
  "no_hp": "08999999999",
  "email": "test@mail.com",
  "alamat": "test address",
  "jenis_kel": "L",
  "tanggal_lahir": "2001-05-12",
  "kategori_cust": "walk in"
}
```

**Example Success Response:**
```json
{
  "status": true,
  "message": "Customers Update Successful.",
  "data": [
    {
      "id": "1",
      "id_pos": null,
      "nama": "Jowo Kidodo",
      "no_hp": "08888888888888",
      "email": "a@test.com",
      "alamat": "jl. jl",
      "jenis_kel": "L",
      "tanggal_lahir": null,
      "kategori_cust": "new",
      "datecreated": "2026-03-16 08:49:06",
      "value_pts": "0"
    }
  ]
}
```

### `pos_customer delete`
* **Method**: `DELETE`
* **URL**: `{{base_url}}pos_customers/:id`

**Example Success Response:**
```json
{
  "status": true,
  "message": "Customer Delete Successful."
}
```

---

## 5. Items

### `pos_items get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_items`

**Example Success Response:**
```json
{
    "status": true,
    "items": [
        {
            "id": "159",
            "brand_id": "30",
            "category_id": "31",
            "name": "Cookies Sundae",
            "description": "",
            "price": "16000.00",
            "cost": "0.00",
            "discount_total": "0.00",
            "discount_type": "percent",
            "order_types": [
                {
                    "dinein": "16000"
                },
                {
                    "gofood": "20800"
                },
                {
                    "shopeefood": "20800"
                },
                {
                    "grabfood": "20800"
                },
                {
                    "tiktok": "20800"
                }
            ],
            "sku": "X-00411",
            "barcode": "77606429771",
            "stock_quantity": "0",
            "min_stock_level": "0",
            "image_url": "",
            "tax_rate": "0.00",
            "locations": "",
            "units": {
                "main_unit": "",
                "main_price": "",
                "additional_units": []
            },
            "is_available": "yes",
            "sort_order": "0",
            "status": "active",
            "parent": null,
            "children": null,
            "created_at": "2026-05-04 15:37:14",
            "updated_at": "2026-05-04 15:37:14",
            "group_names": [
                {
                    "id": "30",
                    "name": "XIE XIE ICE CREAM"
                }
            ]
        },
        {
            "id": "223",
            "brand_id": "30",
            "category_id": "7",
            "name": "Happy",
            "description": "",
            "price": "16000.00",
            "cost": "0.00",
            "discount_total": "0.00",
            "discount_type": "percent",
            "order_types": [
                {
                    "dinein": "16000"
                },
                {
                    "gofood": "16000"
                },
                {
                    "shopeefood": "16000"
                },
                {
                    "grabfood": "16000"
                },
                {
                    "tiktok": "16000"
                }
            ],
            "sku": "X-00575",
            "barcode": "97923513351",
            "stock_quantity": "0",
            "min_stock_level": "0",
            "image_url": "",
            "tax_rate": "0.00",
            "locations": "",
            "units": {
                "main_unit": "",
                "main_price": "",
                "additional_units": []
            },
            "is_available": "yes",
            "sort_order": "0",
            "status": "active",
            "parent": null,
            "children": "[572,573,574]",
            "created_at": "2026-05-07 11:20:44",
            "updated_at": "2026-05-07 11:20:44",
            "group_names": [
                {
                    "id": "30",
                    "name": "XIE XIE ICE CREAM"
                }
            ]
        },
        {
            "id": "572",
            "brand_id": "30",
            "category_id": "7",
            "name": "Happy-Nut",
            "description": "",
            "price": "16000.00",
            "cost": "16000.00",
            "discount_total": "0.00",
            "discount_type": "",
            "order_types": [
                {
                    "dinein": "16000.00"
                },
                {
                    "gofood": "16000.00"
                },
                {
                    "shopeefood": "16000.00"
                },
                {
                    "grabfood": "16000.00"
                },
                {
                    "tiktok": "16000.00"
                }
            ],
            "sku": "X-00572",
            "barcode": "34189251276",
            "stock_quantity": "0",
            "min_stock_level": "0",
            "image_url": "",
            "tax_rate": "0.00",
            "locations": "",
            "units": "",
            "is_available": "yes",
            "sort_order": "0",
            "status": "active",
            "parent": "223",
            "children": "[]",
            "created_at": "2026-05-07 11:20:44",
            "updated_at": "2026-05-07 11:20:44",
            "group_names": [
                {
                    "id": "30",
                    "name": "XIE XIE ICE CREAM"
                }
            ]
        }
    ]
}
```

### `pos_items post`
* **Method**: `POST`
* **URL**: `{{base_url}}pos_items`
* **Body (multipart-form)**: `brand_id`, `category_id`, `name`, `description`, `price`, `cost`, `sku`, `stock_quantity`, `min_stock_level`, `image_url`, `tax_rate`, `locations`, `units`, `is_available`, `status`

**Example Success Response:**
```json
{
  "status": true,
  "message": "POS item added successfully.",
  "data": [
    {
      "id": "8",
      "brand_id": "1",
      "category_id": "13",
      "name": "kentang goreng",
      "description": "kentang goreng apa bukan",
      "price": "25000.00",
      "cost": "22000.00",
      "sku": "abc",
      "barcode": "59465605612",
      "stock_quantity": "0",
      "min_stock_level": "0",
      "image_url": "kentang.jpg",
      "tax_rate": "0.00",
      "locations": "",
      "units": "",
      "is_available": "yes",
      "sort_order": "0",
      "status": "active",
      "created_at": "2026-03-18 14:51:35",
      "updated_at": "2026-03-18 14:51:35",
      "group_names": [
        {
          "id": "1",
          "name": "ABC TEST"
        }
      ]
    }
  ]
}
```

### `pos_items put`
* **Method**: `PUT`
* **URL**: `{{base_url}}pos_items/:id`
* **Body (json)**:
```json
{
  "brand_id": "1",
  "category_id": "27",
  "name": "test item",
  "description": "test description",
  "price": "5000",
  "cost": "2000",
  "sku": "test sku",
  "stock_quantity": "1",
  "min_stock_level": "1",
  "image_url": "test.url",
  "status": "active"
}
```

**Example Success Response:**
```json
{
  "status": true,
  "message": "POS item updated successfully.",
  "data": [
    {
      "id": "8",
      "brand_id": "1",
      "category_id": "27",
      "name": "kentang goreng",
      "description": "kentang goreng apa bukan",
      "price": "25000.00",
      "cost": "22000.00",
      "sku": "abc",
      "barcode": "59465605612",
      "stock_quantity": "0",
      "min_stock_level": "0",
      "image_url": "kentang.jpg",
      "tax_rate": "0.00",
      "locations": "",
      "units": "",
      "is_available": "yes",
      "sort_order": "0",
      "status": "active",
      "created_at": "2026-03-18 14:51:35",
      "updated_at": "2026-03-18 14:53:44",
      "group_names": [
        {
          "id": "1",
          "name": "ABC TEST"
        }
      ]
    }
  ]
}
```

### `pos_items delete`
* **Method**: `DELETE`
* **URL**: `{{base_url}}pos_items/:id`

**Example Success Response:**
```json
{
  "status": true,
  "message": "POS item deleted successfully."
}
```

---

## 6. Orders

### `pos_order get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_order`

**Example Success Response (Partial):**
```json
[
    {
        "id": "5",
        "id_pos": "25129bc1-ab90-4da7-abd9-fae76ea422f5",
        "sent": "0",
        "datesend": null,
        "clientid": "1",
        "biller_id": null,
        "deleted_customer_name": null,
        "number": "3",
        "prefix": "POS-",
        "number_format": "1",
        "formatted_number": "POS-000003",
        "datecreated": "2026-04-14 13:24:57",
        "date": "2026-04-14",
        "duedate": null,
        "currency": "3",
        "subtotal": "58000.00",
        "shipping_fee": "0.00",
        "total_tax": "0.00",
        "total": "58000.00",
        "customer_deposit": "0.00",
        "weight_est": "0",
        "adjustment": "0.00",
        "addedfrom": "0",
        "hash": "d29bc2386367ba78691b5b4eb2b07747",
        "status": "2",
        "clientnote": "",
        "adminnote": null,
        "last_overdue_reminder": null,
        "last_due_reminder": null,
        "cancel_overdue_reminders": "0",
        "allowed_payment_modes": "a:1:{i:0;s:1:\"4\";}",
        "token": null,
        "discount_percent": "0.00",
        "discount_total": "0.00",
        "discount_type": "",
        "recurring": "0",
        "recurring_type": null,
        "custom_recurring": "0",
        "cycles": "0",
        "total_cycles": "0",
        "is_recurring_from": null,
        "last_recurring_date": null,
        "terms": "Dine In",
        "sale_agent": "0",
        "billing_street": "-",
        "billing_city": null,
        "billing_state": null,
        "billing_zip": null,
        "billing_country": null,
        "shipping_street": null,
        "shipping_city": null,
        "shipping_state": null,
        "shipping_zip": null,
        "shipping_country": null,
        "include_shipping": null,
        "show_shipping_on_invoice": "1",
        "show_quantity_as": "1",
        "project_id": "0",
        "subscription_id": "0",
        "short_link": null,
        "expedition_id": "a:0:{}",
        "updatedat": "2026-04-14 00:00:00",
        "updatedby": "0",
        "symbol": "Rp.",
        "name": "Indonesian Rupiah",
        "decimal_separator": ".",
        "thousand_separator": ",",
        "placement": "before",
        "isdefault": "1",
        "id_point": "2",
        "id_invoice": "5",
        "id_cust": "1",
        "value_pts": "6",
        "keterangan": null,
        "currencyid": "3",
        "currency_name": "Indonesian Rupiah",
        "points": "6"
    }
]
```

### `pos_order search_get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_order/search/:keyword`

**Example Success Response:**
```json
[
    {
        "id": "4",
        "id_pos": "45362-bfy1-123edf",
        "sent": "0",
        "datesend": null,
        "clientid": "1",
        "biller_id": null,
        "deleted_customer_name": null,
        "number": "23",
        "prefix": "POS-",
        "number_format": "1",
        "formatted_number": "POS-000023",
        "datecreated": "2026-04-07 00:00:00",
        "date": "2026-03-17",
        "duedate": null,
        "currency": "3",
        "subtotal": "100000.00",
        "shipping_fee": "0.00",
        "total_tax": "0.00",
        "total": "100000.00",
        "customer_deposit": "0.00",
        "weight_est": "0",
        "adjustment": "0.00",
        "addedfrom": "0",
        "hash": "6367eb47ba1c7653affe10324baa1036",
        "status": "1",
        "clientnote": "Dummy test",
        "adminnote": null,
        "last_overdue_reminder": null,
        "last_due_reminder": null,
        "cancel_overdue_reminders": "0",
        "allowed_payment_modes": "a:1:{i:0;s:1:\"4\";}",
        "token": null,
        "discount_percent": "0.00",
        "discount_total": "0.00",
        "discount_type": "",
        "recurring": "0",
        "recurring_type": null,
        "custom_recurring": "0",
        "cycles": "0",
        "total_cycles": "0",
        "is_recurring_from": null,
        "last_recurring_date": null,
        "terms": null,
        "sale_agent": "0",
        "billing_street": "Jl. Testing No. 123",
        "billing_city": null,
        "billing_state": null,
        "billing_zip": null,
        "billing_country": null,
        "shipping_street": null,
        "shipping_city": null,
        "shipping_state": null,
        "shipping_zip": null,
        "shipping_country": null,
        "include_shipping": null,
        "show_shipping_on_invoice": "1",
        "show_quantity_as": "1",
        "project_id": "0",
        "subscription_id": "0",
        "short_link": null,
        "expedition_id": "a:0:{}",
        "updatedat": null,
        "updatedby": null,
        "nama": "Rend Ray",
        "no_hp": "628951472258",
        "email": "",
        "alamat": "Wonogiri",
        "jenis_kel": "",
        "tanggal_lahir": null,
        "kategori_cust": "",
        "invoiceid": "4",
        "customer_id": "1"
    }
]
```

### `pos_order post`
* **Method**: `POST`
* **URL**: `{{base_url}}pos_order`
* **Body (json)**:
```json
{
  "clientid": 1,
  "id_pos": "test-test-test",
  "date": "2026-03-17",
  "currency": 3,
  "prefix": "POS-",
  "newitems": [
    {
      "description": "Produk dummy",
      "long_description": "Produk dummy untuk test API POS order",
      "qty": "1",
      "rate": "100000.00",
      "order": "1",
      "unit": "",
      "taxname": []
    }
  ],
  "allowed_payment_modes": ["1"],
  "billing_street": "test street",
  "subtotal": "100000.00",
  "total": "100000.00",
  "clientnote": "Dummy test",
  "terms": "Tunai",
  "discount_percent":"5",
  "discount_total":"5000",
  "discount_type":"percent"
}
```

**Example Success Response:**
```json
[
    {
        "id": "45",
        "id_pos": "117d5153-345c-4807-81d6-f80318bd355a",
        "sent": "0",
        "datesend": null,
        "clientid": "2",
        "biller_id": null,
        "deleted_customer_name": null,
        "number": "10",
        "prefix": "POS-",
        "number_format": "1",
        "formatted_number": "POS-000010",
        "datecreated": "2026-04-03 17:08:33",
        "date": "2026-04-03",
        "duedate": null,
        "currency": "3",
        "subtotal": "45998.00",
        "shipping_fee": "0.00",
        "total_tax": "0.00",
        "total": "42778.00",
        "customer_deposit": "0.00",
        "weight_est": "0",
        "adjustment": "0.00",
        "addedfrom": "0",
        "hash": "60195899e7717d10f7838f1a1173df7e",
        "status": "2",
        "clientnote": "😭😭😭<br />\n---ITEM NOTES---<br />\nAyam mati | Delivery - 😂😂😂<br />\nAyam Cocol Korea | Take Away - hgh",
        "adminnote": null,
        "last_overdue_reminder": null,
        "last_due_reminder": null,
        "cancel_overdue_reminders": "0",
        "allowed_payment_modes": "a:1:{i:0;s:1:\"4\";}",
        "token": null,
        "discount_percent": "7.00",
        "discount_total": "3219.86",
        "discount_type": "percent",
        "recurring": "0",
        "recurring_type": null,
        "custom_recurring": "0",
        "cycles": "0",
        "total_cycles": "0",
        "is_recurring_from": null,
        "last_recurring_date": null,
        "terms": "Dine In",
        "sale_agent": "0",
        "billing_street": "Wonogiri",
        "billing_city": null,
        "billing_state": null,
        "billing_zip": null,
        "billing_country": null,
        "shipping_street": null,
        "shipping_city": null,
        "shipping_state": null,
        "shipping_zip": null,
        "shipping_country": null,
        "include_shipping": null,
        "show_shipping_on_invoice": "1",
        "show_quantity_as": "1",
        "project_id": "0",
        "subscription_id": "0",
        "short_link": null,
        "expedition_id": "a:0:{}",
        "updatedat": "2026-04-03 00:00:00",
        "updatedby": "0",
        "symbol": "Rp.",
        "name": "Indonesian Rupiah",
        "decimal_separator": ".",
        "thousand_separator": ",",
        "placement": "before",
        "isdefault": "1",
        "id_point": "49",
        "id_invoice": "45",
        "id_cust": "2",
        "value_pts": "4",
        "keterangan": null,
        "currencyid": "3",
        "currency_name": "Indonesian Rupiah",
        "points": "4"
    }
]
```

### `pos_order put`
* **Method**: `PUT`
* **URL**: `{{base_url}}pos_order/:id`
* **Body (json)**: 
```json
{
  "clientid": "1",
  "number": "100",
  "date": "2026-03-17",
  "currency": "3",
  "status": 5, // ini status 
  "billing_street": "test street",
  "allowed_payment_modes": ["1"],
  "items": [
    {
      "itemid": "80",
      "description": "Produk dummy",
      "long_description": "test update",
      "qty": "3",
      "rate": "15000",
      "unit": "",
      "taxname": [],
      "order": 1
    }
  ],
  "subtotal": "45000.00",
  "total": "45000.00"
}
```
**Example Success Response:**
```json
{
    "status": true,
    "message": "Invoice Updated Successfully",
    "data": {
        "id": "1",
        "id_pos": "45362-bfy1-123edf",
        "sent": "0",
        "datesend": null,
        "clientid": "2",
        "biller_id": null,
        "deleted_customer_name": null,
        "number": "1",
        "prefix": "POS-",
        "number_format": "1",
        "formatted_number": "POS-000001",
        "datecreated": "2026-04-22 15:54:33",
        "date": "2026-04-22",
        "duedate": null,
        "currency": "3",
        "subtotal": "54000.00",
        "shipping_fee": "0.00",
        "total_tax": "0.00",
        "total": "54000.00",
        "customer_deposit": "0.00",
        "weight_est": "0",
        "adjustment": "0.00",
        "addedfrom": "0",
        "hash": "0b8f3d3abc1e95ebde67740a6348585c",
        "status": "1",
        "clientnote": "test",
        "adminnote": null,
        "last_overdue_reminder": null,
        "last_due_reminder": null,
        "cancel_overdue_reminders": "0",
        "allowed_payment_modes": "a:3:{i:0;s:1:\"7\";i:1;s:1:\"8\";i:2;s:1:\"9\";}",
        "token": null,
        "discount_percent": "0.00",
        "discount_total": "0.00",
        "discount_type": "",
        "recurring": "0",
        "recurring_type": null,
        "custom_recurring": "0",
        "cycles": "0",
        "total_cycles": "0",
        "is_recurring_from": null,
        "last_recurring_date": null,
        "terms": "Dine In",
        "sale_agent": "0",
        "billing_street": "Wonogiri",
        "billing_city": null,
        "billing_state": null,
        "billing_zip": null,
        "billing_country": null,
        "shipping_street": null,
        "shipping_city": null,
        "shipping_state": null,
        "shipping_zip": null,
        "shipping_country": null,
        "include_shipping": null,
        "show_shipping_on_invoice": "1",
        "show_quantity_as": "1",
        "project_id": "0",
        "subscription_id": "0",
        "short_link": null,
        "expedition_id": "a:0:{}",
        "updatedat": null,
        "updatedby": null,
        "symbol": "Rp.",
        "name": "Indonesian Rupiah",
        "decimal_separator": ".",
        "thousand_separator": ",",
        "placement": "before",
        "isdefault": "1",
        "id_point": "1",
        "id_invoice": "1",
        "id_cust": "1",
        "value_pts": "5",
        "keterangan": null,
        "currencyid": "3",
        "currency_name": "Indonesian Rupiah",
        "points": "5",
        "total_left_to_pay": "54000.00",
        "items": [
            {
                "id": "1",
                "rel_id": "1",
                "rel_type": "invoice",
                "description": "Red Velvet",
                "long_description": "Red Velvet",
                "qty": "2.00",
                "rate": "18000.00",
                "unit": "",
                "weight": "0",
                "is_optional": false,
                "is_selected": true,
                "item_order": "1",
                "wh_delivered_quantity": "0.00",
                "taxes": []
            }
        ],
        "attachments": [],
        "visible_attachments_to_customer_found": false,
        "client": [
            {
                "id": "2",
                "nama": "Rizki",
                "no_hp": "6289508225411",
                "alamat": "Wonogiri",
                "datecreated": "2026-04-22 10:07:19",
                "value_pts": "0"
            }
        ],
        "payments": [],
        "scheduled_email": null
    }
}
```

### `pos_order delete`
* **Method**: `DELETE`
* **URL**: `{{base_url}}pos_order/:id`

**Example Success Response:**
```json
{
  "status": true,
  "message": "POS Order Deleted Successfully"
}
```

---

## 7. Reports

### `get customers_report`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_reports?type=customers_report`

**Example Success Response:**
```json
[
    {
        "clientid": "3",
        "nama": "test",
        "total_invoices": "3",
        "total_sales": "192000.00",
        "net_total": "192000.00",
        "points": "18",
        "datecreated": "2026-04-14 11:43:05"
    }
]
```

### `get invoices_report`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_reports?type=invoices_report&date_from=2026-04-01&date_to=2026-04-03`

**Example Success Response:**
```json
[
    {
        "invoiceid": "5",
        "number": "3",
        "formatted_number": "POS-000003",
        "clientid": "1",
        "nama": "Walk In",
        "year": "2026",
        "date": "2026-04-14",
        "duedate": null,
        "subtotal": "58000.00",
        "total": "58000.00",
        "net_sales": "58000.00",
        "total_tax": "0.00",
        "discount_total": "0.00",
        "status": "2",
        "items": [
            {
                "qty": 1,
                "rate": 9000,
                "description": "Ice Cream Coffee",
                "long_description": "Ice Cream Coffee"
            },
            {
                "qty": 1,
                "rate": 9000,
                "description": "Ice Cream Mix",
                "long_description": "Ice Cream Mix"
            },
            {
                "qty": 1,
                "rate": 8000,
                "description": "Ice Cream Coklat",
                "long_description": "Ice Cream Coklat"
            },
            {
                "qty": 2,
                "rate": 16000,
                "description": "Boba Sundae",
                "long_description": "Boba Sundae"
            }
        ]
    }
]
```

### `get items_report`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_reports?type=items_report&date_from=2026-04-01&date_to=2026-04-04`

**Example Success Response:**
```json
[
    {
        "name": "Ice Cream Coffee",
        "qty_sold": "2.00",
        "total_sold": "18000.0000",
        "avg_sold": "9000.00000000",
        "cost": "0.00",
        "price": "9000.00",
        "brand": "XIE XIE ICE CREAM"
    }
]
```

### `get payments_report`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_reports?type=payments_report&date_from=2026-03-01&date_to=2026-04-01`

**Example Success Response:**
```json
[
    {
        "paymentid": "5",
        "date": "2026-04-14",
        "invoiceid": "5",
        "clientid": "1",
        "nama": "Walk In",
        "paymentmode": "4",
        "transactionid": "",
        "note": "",
        "amount": "58000.00",
        "points": "6"
    }
]
```

---

## 8. Transactions

### `pos_transaction get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_transaction`

**Example Success Response:**
```json
[
    {
        "id": "5",
        "id_pos": "25129bc1-ab90-4da7-abd9-fae76ea422f5",
        "invoiceid": "5",
        "amount": "58000.00",
        "paymentmode": "4",
        "paymentmethod": "Rp. 100.000",
        "date": "2026-04-14",
        "daterecorded": "2026-04-14 13:28:33",
        "note": "",
        "transactionid": ""
    }
]
```

### `pos_transaction search_get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_transaction/search/:keyword`

**Example Success Response:**
```json
[
    {
        "id": "10",
        "id_pos": "550b25f3-8b7e-4110-bb90-d0925b79bcb3",
        "invoiceid": "10",
        "amount": "250000.00",
        "paymentmode": "4",
        "paymentmethod": "Rp. 250.000",
        "date": "2026-04-14",
        "daterecorded": "2026-04-14 13:56:20",
        "note": "",
        "transactionid": "",
        "nama": "walk in",
        "no_hp": null,
        "email": null,
        "alamat": null,
        "jenis_kel": null,
        "tanggal_lahir": null,
        "kategori_cust": null,
        "datecreated": "2026-04-14 13:33:42",
        "sent": "0",
        "datesend": null,
        "clientid": "1",
        "biller_id": null,
        "deleted_customer_name": null,
        "number": "8",
        "prefix": "POS-",
        "number_format": "1",
        "formatted_number": "POS-000008",
        "duedate": null,
        "currency": "3",
        "subtotal": "250000.00",
        "shipping_fee": "0.00",
        "total_tax": "0.00",
        "total": "250000.00",
        "customer_deposit": "0.00",
        "weight_est": "0",
        "adjustment": "0.00",
        "addedfrom": "0",
        "hash": "b56d82dd250e44da472ee918ef5d9804",
        "status": "2",
        "clientnote": "",
        "adminnote": null,
        "last_overdue_reminder": null,
        "last_due_reminder": null,
        "cancel_overdue_reminders": "0",
        "allowed_payment_modes": "a:1:{i:0;s:1:\"4\";}",
        "token": null,
        "discount_percent": "0.00",
        "discount_total": "0.00",
        "discount_type": "",
        "recurring": "0",
        "recurring_type": null,
        "custom_recurring": "0",
        "cycles": "0",
        "total_cycles": "0",
        "is_recurring_from": null,
        "last_recurring_date": null,
        "terms": "Dine In",
        "sale_agent": "0",
        "billing_street": "-",
        "billing_city": null,
        "billing_state": null,
        "billing_zip": null,
        "billing_country": null,
        "shipping_street": null,
        "shipping_city": null,
        "shipping_state": null,
        "shipping_zip": null,
        "shipping_country": null,
        "include_shipping": null,
        "show_shipping_on_invoice": "1",
        "show_quantity_as": "1",
        "project_id": "0",
        "subscription_id": "0",
        "short_link": null,
        "expedition_id": "a:0:{}",
        "updatedat": "2026-04-14 00:00:00",
        "updatedby": "0",
        "paymentid": "11",
        "customer_id": "1"
    }
]
```

### `pos_transaction post`
* **Method**: `POST`
* **URL**: `{{base_url}}pos_transaction`
* **Body (json)**:
```json
{
  "id_pos": "abcde-fghij-klmno",
  "invoiceid": "36",
  "amount": "2500",
  "paymentmode": "cash"
}
```

**Example Success Response:**
```json
{
  "paymentmode": true,
  "message": "Payment add successful.",
  "data": {
    "id": "22",
    "id_pos": "abcde-fghij-klmno",
    "invoiceid": "36",
    "amount": "20000.00",
    "deposit": "0.00",
    "paymentmode": "cash"
  }
}
```

### `pos_transaction put`
* **Method**: `PUT`
* **URL**: `{{base_url}}pos_transaction/:id_transaction`
* **Body (json)**:
```json
{
  "amount": "25000"
}
```

**Example Success Response:**
```json
{
  "status": true,
  "message": "Payment Updated Successfully"
}
```

### `pos_transaction delete`
* **Method**: `DELETE`
* **URL**: `{{base_url}}pos_transaction/:id_transaction`

**Example Success Response:**
```json
{
  "status": true,
  "message": "POS Transaction Deleted Successfully"
}
```


### `pos_options get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_options`
* **PARAMS**: `sync` --> TRUE

**Example Success Response:**
```json
{
    "status": true,
    "data": {
        "version": "1.0.4.2",
        "pos_path": "",
        "changelog": "",
        "pos_tenant_name": "Xie Xie Ice Cream",
        "pos_brand_logo": null,
        "pos_address": "Solo Baru",
        "pos_phone": "6298756438373",
        "pos_social_network": null,
        "pos_label_footer_1": "Selamat menikmati dan kami tunggu kedatangannya kembali",
        "pos_label_footer_2": null,
        "pos_label_footer_3": null,
        "pos_default_discount": "0",
        "pos_app_settings": "{\"display\":{\"show_image\":true,\"show_name\":true,\"show_price\":true,\"show_stock\":true},\"printing\":{\"auto_print\":false}}",
        "ps_next_queue": null,
        "ps_last_queue_date": null,
        "pos_shift_config": null,
        "pos_active_session": ""
    }
}
```

### `pos_options put`
* **Method**: `PUT`
* **URL**: `{{base_url + path}}pos_options`

**Example body Request:**
```
{
    "version": "1.1.1"
}
```
**Example Success Response:**
```json
{
    "status": true,
    "message": "Data updated successfully"
}
```


### `pos_payment_modes get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_payment_modes`

**Example Success Response:**
```json
{
    "status": true,
    "data": [
        {
            "id": "7",
            "name": "Cash",
            "description": "",
            "show_on_pdf": "0",
            "allow_pos": "1",
            "invoices_only": "0",
            "expenses_only": "0",
            "selected_by_default": "0",
            "active": "1"
        },
        {
            "id": "8",
            "name": "Transfer",
            "description": "",
            "show_on_pdf": "0",
            "allow_pos": "1",
            "invoices_only": "0",
            "expenses_only": "0",
            "selected_by_default": "0",
            "active": "1"
        },
        {
            "id": "9",
            "name": "QRIS",
            "description": "",
            "show_on_pdf": "0",
            "allow_pos": "1",
            "invoices_only": "0",
            "expenses_only": "0",
            "selected_by_default": "0",
            "active": "1"
        }
    ]
}
```


### `pos_staff get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_staff`

**Example Success Response:**
```json
[
    {
        "firstname": "RANDI",
        "lastname": "WAHYUDI",
        "email": "randhi.wahyudi@gmail.com",
        "phonenumber": "",
        "role": "Owner",
        "active": "1",
        "password": "$2a$08$MKeRN2XVc9vfV0URypzSyeL/5702vP9rMb5LpdZZvrwAzuhOz37bW",
        "pin": "0000"
    },
    {
        "firstname": "IT",
        "lastname": "Semesta",
        "email": "zxczxc@qwe.qwe",
        "phonenumber": "62846387654",
        "role": "Owner",
        "active": "1",
        "password": "$2a$08$Aqd1f.JJ/2wBXIF0IvqHOeLf94P9wKyIFfnCCFksm9MVODJJbzHmG",
        "pin": "0000"
    },
    {
        "firstname": "NUR",
        "lastname": "MUTTAQIN",
        "email": "qwe@qwe.qwe",
        "phonenumber": "131513213124",
        "role": "Kitchen",
        "active": "1",
        "password": "$2a$08$kbxJQGYWolKc8h8sufHF9OWYF5iS7WfK5Uh7ThUzRUfGNGv6G05ci",
        "pin": "0000"
    },
    {
        "firstname": "Kasir",
        "lastname": "Pagi",
        "email": "qweqwe@qwewq.dfg",
        "phonenumber": "",
        "role": "Cashier",
        "active": "1",
        "password": "$2a$08$cjgsvgu4hIa0K3/kTUIYrezQ4qpMvnHUJc6GMPW4yTEi/jsepf.2G",
        "pin": "0000"
    }
]
```


### `pos_shift_logs get`
* **Method**: `GET`
* **URL**: `{{base_url + path}}pos_shift_logs`

**Example Success Response:**
```json
{
    "status": true,
    "message": "Success",
    "data": [
        {
            "id": "1",
            "date": "2026-04-22",
            "name": "Kasir",
            "shift": "Pagi",
            "login_at": null,
            "logout_at": null,
            "transactions": [
                []
            ]
        }
    ]
}
```

### `pos_shift_logs post`
* **Method**: `POST`
* **URL**: `{{base_url + path}}pos_shift_logs`
* **Body (json)**:
```json
{
    "date": "2026-04-22 11:38:00",
    "name": "Kasir", 
    "shift": "Pagi",
    "transactions": [{}] // detail seluruh payment_modes dan order_type, dan juga total, selisih dan status
}
```
**Example Success Response:**
```json
{
    "status": true,
    "message": "Shift log created successfully",
    "data": {
        "date": "2026-04-22 11:38:00",
        "name": "Kasir",
        "shift": "Pagi",
        "transactions": [
            []
        ],
        "id": 1
    }
}
```


### `credit_notes GET`
* **Method**: `GET`
* **URL**: `{{base_url + path}}credit_notes`

**Example Success Response:**
```json
[
    {
        "id": "1",
        "clientid": "4",
        "deleted_customer_name": null,
        "number": "1",
        "prefix": "CN-",
        "number_format": "1",
        "formatted_number": "CN-000001",
        "datecreated": "2026-04-24 10:11:01",
        "date": "2026-04-24",
        "adminnote": "",
        "terms": "",
        "clientnote": "",
        "currency": "3",
        "subtotal": "19000.00",
        "total_tax": "0.00",
        "total": "19000.00",
        "adjustment": "0.00",
        "addedfrom": "1",
        "status": "2",
        "project_id": "0",
        "discount_percent": "0.00",
        "discount_total": "0.00",
        "discount_type": "",
        "billing_street": "",
        "billing_city": "",
        "billing_state": "",
        "billing_zip": "",
        "billing_country": "0",
        "shipping_street": null,
        "shipping_city": null,
        "shipping_state": null,
        "shipping_zip": null,
        "shipping_country": null,
        "include_shipping": "0",
        "show_shipping_on_credit_note": "1",
        "show_quantity_as": "1",
        "reference_no": "POS-000025",
        "symbol": "Rp.",
        "name": "Indonesian Rupiah",
        "decimal_separator": ".",
        "thousand_separator": ",",
        "placement": "before",
        "isdefault": "1",
        "currencyid": "3",
        "currency_name": "Indonesian Rupiah",
        "customfields": []
    }
]
```

### `credit_notes specific GET`
* **Method**: `GET`
* **URL**: `{{base_url + path}}credit_notes/:id`

**Example Success Response:**
```json
{
    "id": "1",
    "clientid": "4",
    "deleted_customer_name": null,
    "number": "1",
    "prefix": "CN-",
    "number_format": "1",
    "formatted_number": "CN-000001",
    "datecreated": "2026-04-24 10:11:01",
    "date": "2026-04-24",
    "adminnote": "",
    "terms": "",
    "clientnote": "",
    "currency": "3",
    "subtotal": "19000.00",
    "total_tax": "0.00",
    "total": "19000.00",
    "adjustment": "0.00",
    "addedfrom": "1",
    "status": "2",
    "project_id": "0",
    "discount_percent": "0.00",
    "discount_total": "0.00",
    "discount_type": "",
    "billing_street": "",
    "billing_city": "",
    "billing_state": "",
    "billing_zip": "",
    "billing_country": "0",
    "shipping_street": null,
    "shipping_city": null,
    "shipping_state": null,
    "shipping_zip": null,
    "shipping_country": null,
    "include_shipping": "0",
    "show_shipping_on_credit_note": "1",
    "show_quantity_as": "1",
    "reference_no": "POS-000025",
    "symbol": "Rp.",
    "name": "Indonesian Rupiah",
    "decimal_separator": ".",
    "thousand_separator": ",",
    "placement": "before",
    "isdefault": "1",
    "currencyid": "3",
    "currency_name": "Indonesian Rupiah",
    "refunds": [
        {
            "id": "1",
            "credit_note_id": "1",
            "staff_id": "1",
            "refunded_on": "2026-04-24",
            "payment_mode": "7",
            "note": "",
            "amount": "19000.00",
            "created_at": "2026-04-24 10:11:59",
            "payment_mode_id": "7",
            "payment_mode_name": "Cash"
        }
    ],
    "total_refunds": "19000.00",
    "applied_credits": [],
    "remaining_credits": "0.00",
    "credits_used": null,
    "items": [
        {
            "id": "75",
            "rel_id": "1",
            "rel_type": "credit_note",
            "description": "Boba Sundae",
            "long_description": "Boba Sundae",
            "qty": "1.00",
            "rate": "19000.00",
            "is_refund": "0",
            "unit": "",
            "weight": "0",
            "is_optional": false,
            "is_selected": true,
            "item_order": "1",
            "wh_delivered_quantity": "0.00",
            "taxes": [],
            "customfields": []
        }
    ],
    "client": {
        "userid": "4",
        "company": "caca",
        "vat": null,
        "phonenumber": "085792862721",
        "country": "103",
        "city": null,
        "zip": null,
        "state": null,
        "address": "",
        "website": null,
        "datecreated": "2026-04-23 14:30:04",
        "active": "1",
        "leadid": null,
        "billing_street": null,
        "billing_city": null,
        "billing_state": null,
        "billing_zip": null,
        "billing_country": "0",
        "shipping_street": null,
        "shipping_city": null,
        "shipping_state": null,
        "shipping_zip": null,
        "shipping_country": "0",
        "longitude": null,
        "latitude": null,
        "default_language": null,
        "default_currency": "0",
        "show_primary_contact": "0",
        "stripe_id": null,
        "registration_confirmed": "1",
        "addedfrom": "0",
        "balance": null,
        "balance_as_of": null
    },
    "attachments": [],
    "customfields": []
}
```


### `pos_staff POST`
* **Method**: `POST`
* **URL**: `{{base_url + path}}pos_staff`
**Body:**
```json
{
    "firstname": "test",
    "lastname": "doang",
    "email":"[EMAIL_ADDRESS]",
    "password":"12345678",
    "pin":"0000",
    "admin":0 | 1,
    "role": [ID]
}
```
[EMAIL_ADDRESS] --> di generate manual dari firstname + .notreal@email.com
[ID] --> 1: Owner, 2: Cashier, 3: Kitchen, 4: Supervisor
lastname wajib: kalau kosong default "-"

**Example Success Response:**
```json
{
    "status": true,
    "message": "Data Inserted Successfully",
    "data": {
        "staffid": "7",
        "email": "test@test.test",
        "firstname": "test",
        "lastname": "doang",
        "facebook": null,
        "linkedin": null,
        "phonenumber": null,
        "skype": null,
        "password": "$2a$08$Xm.65f5Ppjmv2dD8Hp/V.OpNYDKD6xEv7ngG3.l4JtfZn2vo6gHJK",
        "pin": "0000",
        "datecreated": "2026-05-01 09:50:25",
        "profile_image": null,
        "last_ip": null,
        "last_login": null,
        "is_logged_in": null,
        "last_activity": null,
        "last_password_change": null,
        "new_pass_key": null,
        "new_pass_key_requested": null,
        "admin": "0",
        "role": "3",
        "active": "1",
        "default_language": null,
        "direction": null,
        "media_path_slug": "test-doang",
        "is_not_staff": "0",
        "hourly_rate": "0.00",
        "two_factor_auth_enabled": "0",
        "two_factor_auth_code": null,
        "two_factor_auth_code_requested": null,
        "email_signature": null,
        "google_auth_secret": null,
        "full_name": "test doang",
        "permissions": []
    }
}
```

### `pos_promotions GET`
* **Method**: `GET`
* **URL**: `{{Base URL (pos perfex local) + path}}pos_promotions?id_location=[:id]`
* **PARAMS**: 
- id_location : id lokasi dari data saat login berhasil
- status : 0 -> tidak aktif | 1 -> aktif

**Example Success Response:**
```json
[
    {
        "id": "4",
        "name": "PROMO GO",
        "promo_type": "discount",
        "brands": [
            "30",
            "32"
        ],
        "locations": [
            "1071"
        ],
        "description": "",
        "terms_conditions": "",
        "items": {
            "items": [
                {
                    "item_id": "31",
                    "discount_type": "percent",
                    "discount": "100",
                    "discount_value": "8000"
                },
                {
                    "item_id": "79",
                    "discount_type": "fixed",
                    "discount": "0",
                    "discount_value": "0"
                },
                {
                    "item_id": "80",
                    "discount_type": "fixed",
                    "discount": "4000",
                    "discount_value": "4000"
                },
                {
                    "item_id": "81",
                    "discount_type": "fixed",
                    "discount": "4000",
                    "discount_value": "4000"
                },
                {
                    "item_id": "82",
                    "discount_type": "fixed",
                    "discount": "4000",
                    "discount_value": "4000"
                },
                {
                    "item_id": "144",
                    "discount_type": "fixed",
                    "discount": "7000",
                    "discount_value": "7000"
                }
            ]
        },
        "order_types": [
            "dinein"
        ],
        "start_date": "2026-05-13",
        "end_date": "2026-05-16",
        "is_multiplied": "0",
        "is_stackable": "0",
        "status": "1",
        "created_at": "2026-05-13 15:55:31"
    }
]
```