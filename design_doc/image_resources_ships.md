# 船只图片资源

## 概述

船只图片资源包括玩家船只和敌方船只。船只永远固定在屏幕中央（垂直方向会有轻微呼吸动画），战斗时会发生位移和沉没动画。

---

## 资源列表

### 1. 玩家船只 (Player Ship)

| Asset ID | 路径 | 描述 |
| :--- | :--- | :--- |
| IMG_SHIP_PLAYER_0 | `assets/images/ships/Player_ship_0.png` | 初始海盗船 (0级) |
| IMG_SHIP_PLAYER_1 | `assets/images/ships/Player_ship_1.png` | 升级海盗船 (1级) |
| IMG_SHIP_PLAYER_2 | `assets/images/ships/Player_ship_2.png` | 升级海盗船 (2级) |
| IMG_SHIP_PLAYER_3 | `assets/images/ships/Player_ship_3.png` | 升级海盗船 (3级) |
| IMG_SHIP_PLAYER_4 | `assets/images/ships/Player_ship_4.png` | 升级海盗船 (4级) |
| IMG_SHIP_PLAYER_5 | `assets/images/ships/Player_ship_5.png` | 升级海盗船 (5级) |
| IMG_SHIP_PLAYER_6 | `assets/images/ships/Player_ship_6.png` | 顶级海盗船 (6级) |

- **尺寸**: 约 200x200 像素（显示尺寸）
- **进化机制**: 当且仅当货仓、船体、船员三项升级全部达到下一等级时，外观会自动更新。
- **特点**: 随着等级提升，船只体型变大、帆数增加、装饰更加豪华。
- **动画**: 
  - **呼吸动画**: 垂直方向 ±5 像素的简谐运动（2秒周期）。
  - **沉没动画**: 失败时向下移动 800 像素并消失。

---

### 2. 敌方船只 (Enemy Ship)

| Asset ID | 路径 | 描述 |
| :--- | :--- | :--- |
| IMG_SHIP_ENEMY_0 | `assets/images/ships/concept_art/single_sail_0.png` | 默认敌方单桅海盗船 |

- **尺寸**: 约 200x200 像素（显示尺寸）
- **特点**: 单桅帆船，用于区分玩家船只。
- **动画**:
  - **滑入动画**: 战斗开始时从屏幕右侧滑入（1.5秒）。
  - **沉没动画**: 战败时向下移动 800 像素并消失（2秒）。

---

## 技术实现

### 渲染层级
船只位于 **Layer 2 (ShipLayer)**，不随海浪背景晃动，以保持 UI 稳定性。

### 战斗位移
- **进入战斗**: 玩家船只左移 150 像素，敌方船只滑入。
- **战斗结束**: 玩家船只通过动画归位至中心（1.5秒），敌方船只移除。

### 状态反馈
当前版本暂未使用独立的受损状态图片，受损反馈主要通过顶部的耐久度条展示。

---

返回：[图片资产清单](image_resource_list.md)
