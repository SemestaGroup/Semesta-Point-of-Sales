class PenjualanDetailModel {
  final int idPenjualanDetail;
  final int idPenjualan;
  final int idProduk;
  final int hargaJual;
  final int hargaAwal;
  final int jumlah;
  final int diskon;
  final int subtotal;
  final int totalStock;
  final String? createdAt;
  final String? updatedAt;
  final String? productName;
  final String note;
  final String orderType;
  final String orderTypesJson;
  final int remoteItemId;
  final int discountTotal;   // raw discount value from product (percent value or fixed amount)
  final String discountType; // 'percent' or 'fixed'
  final bool isRefund;
  final int originalQty;

  PenjualanDetailModel({
    this.idPenjualanDetail = 0,
    this.idPenjualan = 0,
    this.idProduk = 0,
    this.hargaJual = 0,
    this.hargaAwal = 0,
    this.jumlah = 0,
    this.diskon = 0,
    this.subtotal = 0,
    this.totalStock = 0,
    this.createdAt,
    this.updatedAt,
    this.productName,
    this.note = "",
    this.orderType = "",
    this.orderTypesJson = "",
    this.remoteItemId = 0,
    this.discountTotal = 0,
    this.discountType = 'percent',
    this.isRefund = false,
    this.originalQty = 0,
  });

  factory PenjualanDetailModel.fromJson(Map<String, dynamic> json) =>
      PenjualanDetailModel(
        idPenjualanDetail: json['id_penjualan_detail'] as int? ?? 0,
        idPenjualan: json['id_penjualan'] as int? ?? 0,
        idProduk: json['id_produk'] as int? ?? 0,
        hargaJual: json['harga_jual'] as int? ?? 0,
        hargaAwal: json['harga_awal'] as int? ?? 0,
        jumlah: json['jumlah'] as int? ?? 0,
        diskon: json['diskon'] as int? ?? 0,
        subtotal: json['subtotal'] as int? ?? 0,
        totalStock: json['total_stock'] as int? ?? 0,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        productName: json['productName'] as String?,
        note: json['note'] as String? ?? "",
        orderType: json['orderType'] as String? ?? "",
        orderTypesJson: json['orderTypesJson'] as String? ?? "",
        remoteItemId: json['remote_item_id'] as int? ?? 0,
        discountTotal: json['discountTotal'] as int? ?? 0,
        discountType: json['discountType'] as String? ?? 'percent',
        isRefund: (json['is_refund']?.toString() == '1' || json['isRefund'] == true),
        originalQty: json['originalQty'] as int? ?? (json['jumlah'] as int? ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'id_penjualan_detail': idPenjualanDetail,
        'id_penjualan': idPenjualan,
        'id_produk': idProduk,
        'harga_jual': hargaJual,
        'harga_awal': hargaAwal,
        'jumlah': jumlah,
        'diskon': diskon,
        'subtotal': subtotal,
        'total_stock': totalStock,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'productName': productName,
        'note': note,
        'orderType': orderType,
        'orderTypesJson': orderTypesJson,
        'remote_item_id': remoteItemId,
        'discountTotal': discountTotal,
        'discountType': discountType,
        'is_refund': isRefund ? 1 : 0,
        'isRefund': isRefund,
        'originalQty': originalQty,
      };

  PenjualanDetailModel copyWith({
    int? idPenjualanDetail,
    int? idPenjualan,
    int? idProduk,
    int? hargaJual,
    int? hargaAwal,
    int? jumlah,
    int? diskon,
    int? subtotal,
    int? totalStock,
    String? createdAt,
    String? updatedAt,
    String? productName,
    String? note,
    String? orderType,
    String? orderTypesJson,
    int? remoteItemId,
    int? discountTotal,
    String? discountType,
    bool? isRefund,
    int? originalQty,
  }) {
    return PenjualanDetailModel(
      idPenjualanDetail: idPenjualanDetail ?? this.idPenjualanDetail,
      idPenjualan: idPenjualan ?? this.idPenjualan,
      idProduk: idProduk ?? this.idProduk,
      hargaJual: hargaJual ?? this.hargaJual,
      hargaAwal: hargaAwal ?? this.hargaAwal,
      jumlah: jumlah ?? this.jumlah,
      diskon: diskon ?? this.diskon,
      subtotal: subtotal ?? this.subtotal,
      totalStock: totalStock ?? this.totalStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productName: productName ?? this.productName,
      note: note ?? this.note,
      orderType: orderType ?? this.orderType,
      orderTypesJson: orderTypesJson ?? this.orderTypesJson,
      remoteItemId: remoteItemId ?? this.remoteItemId,
      discountTotal: discountTotal ?? this.discountTotal,
      discountType: discountType ?? this.discountType,
      isRefund: isRefund ?? this.isRefund,
      originalQty: originalQty ?? this.originalQty,
    );
  }
}
