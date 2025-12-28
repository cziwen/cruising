/// 商品数据模型
class Goods {
  final String id;
  final String name;
  final String category;
  final double weight; // 重量（kg）
  final String? imagePath; // 物品图标路径

  Goods({
    required this.id,
    required this.name,
    required this.category,
    required this.weight,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'weight': weight,
      'imagePath': imagePath,
    };
  }

  factory Goods.fromJson(Map<String, dynamic> json) {
    return Goods(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      weight: (json['weight'] as num).toDouble(),
      imagePath: json['imagePath'] as String?,
    );
  }
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




