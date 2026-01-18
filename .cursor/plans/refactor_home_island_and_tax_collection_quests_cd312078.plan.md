# 重构主岛与税收领取任务

将剩余的教学任务重构为更细致的步骤，引导玩家返回主岛并领取税收，从而完成整个新手教程。

## 任务组织

- [ ] 在 quests.json 中重构 T08 和 T09 任务 [id: refactor-quests-json-home-island]
- [ ] 更新设计文档，包含新的任务步骤 [id: update-design-doc-quests-refactor]

## 详细方案

1.  **重构任务配置**: 更新 `assets/config/quests.json`，将原有的 `T08` 和 `T09` 拆分为更细致的引导步骤，并添加更好的过渡文本：
    *   `T08a_home_island_intro`: 介绍主岛及其收益功能。
    *   `T08b_open_port_list`: 引导玩家点击“选择目的地”按钮。
    *   `T08c_go_home`: 引导玩家在列表中选择“我的岛屿”并点击“出发”。
    *   `T08d_home_arrival_tip`: 到达主岛后的庆祝和提示。
    *   `T09_collect_tax`: 引导玩家点击税收气泡领取收益。
    *   `T10_tutorial_complete`: 教程结束的总结陈词。
2.  **验证任务条件**: 确认 `QuestSystem` 已支持以下条件（已在之前步骤中完成）：
    *   `ui.portList.opened`
    *   `navigation.isAtSea`
    *   `homeIsland.opened`
    *   `homeIsland.tax_collected_today == true`
3.  **更新设计文档**: 在 `design_doc/2.16_quest_system.md` 中同步更新这些细化后的任务标识符。

### 任务流图
<mermaid>
graph TD
    T07c["T07c: 庆祝升级"] -->|"完成后"| T08a["T08a: 介绍主岛"]
    T08a -->|"点击屏幕"| T08b["T08b: 打开目的地列表"]
    T08b -->|"完成条件: ui.portList.opened"| T08c["T08c: 选择主岛出发"]
    T08c -->|"完成条件: navigation.isAtSea"| T08d["T08d: 到达提示"]
    T08d -->|"触发: after(T08c) && homeIsland.opened"| T09["T09: 领取税收"]
    T09 -->|"完成条件: tax_collected_today"| T10["T10: 教程结束"]
</mermaid>
