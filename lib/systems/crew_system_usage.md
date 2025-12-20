# 船员系统使用说明

## 加成计算公式

### 1. 航速加成
- **公式**: 
  - 加成百分比 = 所有水手的sailorSkill总和 × 0.01
  - 增加的节数 = 基础速度（8节） × 加成百分比
- **效果**: 直接增加船只的航行速度（节）
- **示例**: 3个水手，总技能值150 → 加成百分比 = 150 × 0.01 = 1.5 (150%) → 增加的节数 = 8 × 1.5 = 12节

### 2. 自动修理效率
- **公式**: `每小时恢复耐久 = 所有船工的shipwrightSkill总和 × 0.1`
- **效果**: 每秒检查一次，根据经过的时间自动恢复耐久
- **示例**: 2个船工，总技能值120 → 每小时恢复12点耐久

### 3. 开炮速度加成
- **公式**: `开炮速度加成 = 所有炮手的gunnerSkill总和 × 0.01`
- **效果**: 开炮冷却时间 = 基础冷却 × (1 - 加成)
- **示例**: 2个炮手，总技能值100 → 加成1% → 冷却时间减少1%

## 在GameState中使用

### 获取加成值
```dart
// 当前航速（节），已包含水手加成
int currentSpeed = gameState.currentSpeed;

// 航速加成百分比（用于兼容，实际加成以节为单位）
double sailingBonus = gameState.sailingBonusPercent;

// 自动修理效率（每秒）
double autoRepair = gameState.autoRepairPerSecond;

// 开炮速度（每秒炮数）
double fireRate = gameState.fireRatePerSecond;
```

### 添加船员
```dart
final crew = CrewMember(
  name: '张三',
  sailorSkill: 70,
  shipwrightSkill: 20,
  gunnerSkill: 10,
  salary: 30,
);
gameState.addCrewMember(crew);
```

### 分配职业
```dart
// 在CrewManagementDialog中通过UI分配
// 或直接调用：
gameState.crewManager.assignCrewRole(crew, CrewRole.sailor);
```

### 自动修理
自动修理系统已在`main.dart`中通过定时器自动运行，每秒检查一次。

## 系数调整

在`lib/systems/crew_system.dart`中可以调整加成系数：

```dart
static const double sailingBonusCoefficient = 0.01;      // 航速加成系数
static const double autoRepairCoefficient = 0.1;         // 自动修理系数
static const double fireRateBonusCoefficient = 0.01;    // 开炮速度加成系数
```




