# 商品图标资源

## 概述

商品图标用于交易界面（Trade Dialog）中，展示玩家和商人库存中的物品。所有基础商品均已配备专门的像素风格图片资源。

---

## 资源列表

### 1. 基础商品 (Base Goods)

配置定义见 `assets/config/goods.json`。

| 商品 ID | 名称 | 图标路径 | 视觉描述 (像素风格/星露谷感) |
| :--- | :--- | :--- | :--- |
| `gold` | 金币 | `assets/images/goods/gold.png` | 一叠闪亮的金币，边缘有明显的明暗对比，最上方的一枚带有闪光点。 |
| `food` | 食物 | `assets/images/goods/food.png` | 装着红苹果、面包和绿色蔬菜的质朴木筐，色彩鲜艳且饱满。 |
| `wood` | 木材 | `assets/images/goods/wood.png` | 三根用粗绳捆绑在一起的原木，断面可见清晰的年轮纹理。 |
| `spice` | 香料 | `assets/images/goods/spice.png` | 一个扎着口的小麻袋，袋口漏出一些亮丽的粉末，或是一个带塞的小陶罐。 |
| `metal` | 金属 | `assets/images/goods/metal.png` | 沉重的长方形铁锭/钢锭，带有金属光泽和斜角切面，表面有细微的磨损痕迹。 |

---

## UI 表现

### 物品格 (GoodsSlot)
在 `TradeSystem` 的对话框中，物品格会根据 `imagePath` 加载图片：
- 如果 `imagePath` 不为 `null`，使用 `Image.asset` 加载。
- 如果加载失败或路径为 `null`，根据 ID 显示备用图标：
  - `gold`: `Icons.monetization_on`
  - 其他: `Icons.category`

---

## 维护建议
如需添加新商品，请确保在 `assets/images/goods/` 目录下提供对应的 512x512（或更高分辨率的像素图）资源，并在 `assets/config/goods.json` 中配置对应的 `imagePath`。

---

返回：[图片资产清单](image_resource_list.md)
