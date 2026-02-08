# 海上事件系统 (Sea Event System)

## 概述
海上事件系统旨在增加航行过程中的决策密度和随机性。事件分为“即时通知类”和“交互决策类”。

## 核心参数 (Global Tuning Knobs)
为了保持平衡并防止过度干扰玩家，系统遵循以下全局限制：

| 参数 | 默认值 | 说明 |
| :--- | :--- | :--- |
| `seaEventCooldownHours` | 4 游戏小时 | 两个事件之间的最小间隔。 |
| `maxEventsPerVoyage` | 3 次 | 单次航行（从港口 A 到港口 B）的最大事件触发次数。 |
| `minProgress` | 10% | 航行进度低于此值时不触发事件（刚出港）。 |
| `maxProgress` | 90% | 航行进度高于此值时不触发事件（快到港）。 |
| `eventCheckInterval` | 1 游戏小时 | 每隔 1 游戏小时进行一次事件触发判定。 |

## 事件索引
以下是目前规划的海上核心事件：

1. [风暴 (Sea Storm)](sea_storm.md) - 挑战船只耐久与航行时间的自然灾害。
2. [商船邂逅 (Merchant Ship Encounter)](sea_merchant_ship.md) - 海上的临时贸易机会。
3. [遇难求救 (Distress Call)](sea_distress_call.md) - 关于道德选择与声望/资源的回报。
4. [海盗拦截 (Pirate Intercept)](sea_pirate_intercept.md) - 战斗风险与买路财的权衡。
5. [暗礁/搁浅 (Reef Grounding)](sea_reef_grounding.md) - 航道选择带来的突发故障。
6. [顺风/逆风 (Tailwind/Headwind)](sea_tailwind_headwind.md) - 影响航行效率的环境变化。

## 系统集成
- **导航系统**：事件触发基于 `NavigationSystem` 的进度和 `accumulatedDistance`。
- **战斗系统**：海盗事件可能触发 `CombatSystem` 的单场景战斗。
- **UI 系统**：所有事件通过 `NotificationSystem` (即时类) 或 `PaperDialog` (决策类) 呈现。
- **昼夜系统**：事件使用统一的游戏时钟进行冷却和持续时间计算。
