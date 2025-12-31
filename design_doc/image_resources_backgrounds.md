# 场景背景图片资源

## 概述

场景背景图片用于游戏的主要视觉层，包括多层视差海洋背景和港口背景。所有背景图片均为静态图片，动画效果（滚动、晃动）通过代码实现。

---

## 资源列表

### 1. 多层海洋背景 (Layer 0)

这些资源位于 `assets/images/background/` 目录下，用于构建多层视差背景。

| Asset ID | 路径 | 速度系数 | 描述 |
| :--- | :--- | :--- | :--- |
| IMG_BG_UNDERWATER | `oceanbg_0_underwater.png` | 0.5 | 最底层水下/海平面背景 |
| IMG_BG_WAVE_3 | `oceanbg_0_wave3.png` | 0.3 | 远景波浪（最慢） |
| IMG_BG_WAVE_2 | `oceanbg_0_wave2.png` | 0.7 | 中景波浪 |
| IMG_BG_WAVE_1 | `oceanbg_0_wave1.png` | 0.8 | 近景波浪 |
| IMG_BG_CLOUD_3 | `oceanbg_0_cloud3.png` | 0.3 | 远景云朵（最慢） |
| IMG_BG_CLOUD_2 | `oceanbg_0_cloud2.png` | 0.5 | 中景云朵 |
| IMG_BG_CLOUD_1 | `oceanbg_0_cloud1.png` | 0.7 | 近景云朵 |

- **尺寸**: 1920×1080 像素
- **格式**: PNG（支持透明通道）
- **风格**: 像素风格，休闲像素美术。
- **技术说明**: 每层通过代码实现独立的横向滚动和正弦波晃动效果。

---

### 2. 港口近背景 (Layer 1)

这些资源位于 `assets/images/buildings/` 目录下，作为各港口的特色背景。

| Asset ID | 路径 | 所属港口 | 描述 |
| :--- | :--- | :--- | :--- |
| IMG_PORT_START | `village_stone_0.png` | 起始港 (port_1) | 宁静的小村庄港口 |
| IMG_PORT_TRADE | `business_port.png` | 贸易港 (port_2) | 繁华的商业港口 |
| IMG_PORT_EXOTIC | `exotic_village.png` | 香料港 (port_3) | 异域风情的香料港口 |

---

### 3. UI 与封面背景

这些资源位于 `assets/images/painting/` 目录下，用于非游戏内场景。

| Asset ID | 路径 | 描述 |
| :--- | :--- | :--- |
| IMG_COVER_0 | `Cover_0.png` | 游戏主菜单与加载界面的全屏封面图 |

- **尺寸**: 1920×1080 像素
- **格式**: PNG
- **风格**: 手绘油画感像素美术，表现海盗船与月夜。

- **尺寸**: 1920×1080 像素
- **用途**: 近背景层（Layer 1），在到达港口时滑入。
- **技术说明**: 通过 `NearBackgroundLayer` 管理，在航行到达/离开时应用滑动动画。

---

## 使用说明

### 视差系统
海洋背景由 7 个独立层组成，每层有不同的 `speedMultiplier`。
- **滚动位移** = `totalSailingOffset * speedMultiplier`
- **晃动幅度** = `baseAmplitude * speedMultiplier`

### 港口切换
当 `GameState.currentPort` 变化或 `GameState.isAtSea` 状态切换时，`NearBackgroundLayer` 会根据 `ports.json` 中的配置加载对应的 `backgroundImage`。

---

返回：[图片资产清单](image_resource_list.md)
