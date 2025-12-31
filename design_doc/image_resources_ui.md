# UI 元素图片资源

## 概述

当前的 UI 系统主要基于 Flutter 的标准组件库（Material Design）构建，结合自定义样式实现简约的视觉风格，而非完全依赖外部图片资产。

---

## 核心 UI 构成

### 1. 对话框与面板
- **实现**: 使用 Flutter 的 `Dialog` 和 `Container`。
- **背景**: 白色或半透明灰色背景，带圆角和投影。
- **占位**: 暂未使用 `IMG_UI_PANEL` 等 9 切片图。

### 2. 按钮
- **实现**: 使用 `ElevatedButton` 和 `IconButton`。
- **图标**: 使用 Flutter 材质图标库 (`Icons`)。
  - 交易: `Icons.swap_horiz`
  - 酒馆: `Icons.nightlife`
  - 船厂: `Icons.build`
  - 存档: `Icons.save`
  - 设置: `Icons.settings`

### 3. 状态栏与进度条
- **实现**: 自定义 `CustomPainter` 或 `Container` 堆叠。
- **航行进度条**: `LinearProgressIndicator` 风格的自定义实现。
- **战斗血条**: 基于 `GameState.ship.durability` 的实时渲染。

---

## 预留资源位 (Placeholder)

如果未来需要进一步提升"像素感"，可以考虑替换以下资源：

| 资源类别 | 建议 Asset ID | 说明 |
| :--- | :--- | :--- |
| 按钮背景 | `IMG_UI_BTN` | 替代当前的 Material 按钮 |
| 对话框边框 | `IMG_UI_DIALOG_FRAME` | 替代当前的圆角容器 |
| 职业图标 | `IMG_UI_ICON_CREW_*` | 替代目前的 Emoji 或文字图标 |

---

## 特殊视觉效果 (Layer 2.5)
- **渐变黑屏**: 失败重生时使用 `AnimatedContainer` 实现的颜色遮罩。

---

返回：[图片资产清单](image_resource_list.md)
