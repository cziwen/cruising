# 拆分船只升级任务并增加船厂打开接口

将单个船只升级任务拆分为两个步骤：引导用户打开船厂，然后引导他们进行升级。这涉及为船厂对话框添加状态跟踪并更新任务配置。

## 任务组织

- [ ] 在 GameState 中添加 isShipyardOpened 状态 [id: gamestate-shipyard-state]
- [ ] 在 QuestSystem 中添加 ui.shipyard.opened 条件判定 [id: questsystem-condition-shipyard]
- [ ] 在 ShipyardDialog 中管理 isShipyardOpened 状态 [id: shipyard-dialog-lifecycle]
- [ ] 在 ShipyardDialog 的载货升级按钮上添加 QuestTarget [id: shipyard-dialog-target-cargo]
- [ ] 在 quests.json 中将 T07 任务拆分为 T07a 和 T07b [id: quests-json-split-t07]
- [ ] 在 GameScreen 中添加船厂关闭动作支持，并在任务配置中使用 [id: shipyard-close-action]

## 详细方案

1.  **添加船厂状态跟踪**: 更新 `lib/game/game_state.dart` 以包含 `_isShipyardOpened` 状态和 `setShipyardOpened` 方法。
2.  **任务系统评估船厂状态**: 更新 `lib/systems/quest_system.dart` 以识别并评估 `ui.shipyard.opened` 条件。
3.  **跟踪船厂对话框生命周期**: 更新 `lib/game/shipyard_dialog.dart`，在 `initState` 中调用 `setShipyardOpened(true)`，在 `dispose` 中调用 `setShipyardOpened(false)`。
4.  **高亮升级按钮**: 在 `lib/game/shipyard_dialog.dart` 中使用 ID 为 `ui.shipyard.upgradeCargoButton` 的 `QuestTarget` 包裹载货量升级按钮。
5.  **重构任务配置**: 修改 `assets/config/quests.json`，将 `T07_upgrade_ship` 拆分为 `T07a_open_shipyard` 和 `T07b_upgrade_ship`。
6.  **添加船厂关闭动作**: 在 `lib/screens/game_screen.dart` 中添加对 `ui.shipyard.close` 动作的支持，并在任务配置中使用它以在任务完成后关闭对话框。

### 任务流图
<mermaid>
graph TD
    T06f["T06f: 利润介绍"] -->|"完成后"| T07a["T07a: 打开船厂"]
    T07a -->|"完成条件: ui.shipyard.opened"| T07b["T07b: 升级船只"]
    T07b -->|"完成条件: ship.upgrade_count >= 1"| T08["T08: 我的岛屿"]
</mermaid>
