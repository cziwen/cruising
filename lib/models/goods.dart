/// 商品数据模型
class Goods {
  final String id;
  final String name;
  final double basePrice;
  final String category;
  final double weight; // 重量（kg）

  Goods({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.category,
    required this.weight,
  });
}

/// 港口商品价格
class PortGoodsPrice {
  final String portId;
  final String goodsId;
  final double buyPrice;
  final double sellPrice;
  final int stock;

  PortGoodsPrice({
    required this.portId,
    required this.goodsId,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
  });
}

/// 船只库存项
class ShipInventoryItem {
  final String goodsId;
  int quantity;

  ShipInventoryItem({
    required this.goodsId,
    this.quantity = 0,
  });

  void add(int amount) {
    quantity += amount;
  }

  void remove(int amount) {
    quantity = (quantity - amount).clamp(0, double.infinity).toInt();
  }

  Map<String, dynamic> toJson() {
    return {
      'goodsId': goodsId,
      'quantity': quantity,
    };
  }

  factory ShipInventoryItem.fromJson(Map<String, dynamic> json) {
    return ShipInventoryItem(
      goodsId: json['goodsId'] as String,
      quantity: json['quantity'] as int,
    );
  }
}




