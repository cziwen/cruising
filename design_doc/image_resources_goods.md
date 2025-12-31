# 商品图标资源

## 概述

商品图标用于交易界面（Trade Dialog）中，展示玩家和商人库存中的物品。目前大部分商品使用默认占位图标，金币使用特定图标。

---

## 资源列表

### 1. 基础商品 (Base Goods)

配置定义见 `assets/config/goods.json`。

| 商品 ID | 名称 | 图标路径 | 备注 |
| :--- | :--- | :--- | :--- |
| `gold` | 金币 | `assets/images/pixel-sun-icon.png` | 复用太阳图标作为金币标识 |
| `food` | 食物 | `null` | 使用内置 `Icons.category` 占位 |
| `wood` | 木材 | `null` | 使用内置 `Icons.category` 占位 |
| `spice` | 香料 | `null` | 使用内置 `Icons.category` 占位 |
| `metal` | 金属 | `null` | 使用内置 `Icons.category` 占位 |

---

## UI 表现

### 物品格 (GoodsSlot)
在 `TradeSystem` 的对话框中，物品格会根据 `imagePath` 加载图片：
- 如果 `imagePath` 不为 `null`，使用 `Image.asset` 加载。
- 如果加载失败或路径为 `null`，根据 ID 显示备用图标：
  - `gold`: `Icons.monetization_on`
  - 其他: `Icons.category`

---

## 未来扩展建议
建议为每个商品（食物、木材、香料、金属）设计独立的 32x32 像素图标，以增强界面的视觉丰富度。

---

返回：[图片资产清单](image_resource_list.md)
