# MiniBattleSimulator Buff 配置与开发指南

本文档专门针对 `MiniBattleSimulator` 中的**Buff（状态与异常）系统**提供详尽的配置说明。
与技能系统类似，Buff 同样采用了**静态模板（JSON）+ 动态行为（Lua）**的组合模式。

---

## 一、 静态模板配置 (`res_buff_template.json`)

静态数据统一配置在 `config/res_buff_template.json` 中，主要用于定义 Buff 的基础属性、叠加规则、驱散优先级以及对角色面板属性的直接影响。

### 1.1 核心字段解析
| 字段名 | 类型 | 说明 | 示例 |
| :--- | :--- | :--- | :--- |
| **`ID`** / **`buffId`** | Number | Buff 的唯一标识 ID。 | `9001` |
| **`MainType`** | Number | 主类型：`1`-增益(Good), `2`-减益(Bad), `3`-控制(Control,会跳过回合)。 | `2` (减益) |
| **`SubType`** | Number | 子类型：具体状态标识，用于脚本中的特定判断（如是否为灼烧、眩晕）。 | `1001` |
| **`StackType`** | Number | 叠加类型：`0`-不可叠加, `1`-刷新持续时间, `2`-叠加层数并刷新。 | `1` |
| **`MaxLimit`** | Number | 层数上限：该 Buff 最多可叠加的层数。 | `5` (最多5层) |
| **`DispelGroup`** | Number | 驱散组：用于判定该 Buff 是否可以被特定技能驱散及其优先级。 | `1` |
| **`AttributeType`** | Array | 属性 ID 数组：Buff 直接影响的属性（如 `2`为攻击力, `3`为防御力）。 | `[2, 3]` |
| **`AttributeValue`** | Array | 属性固定值数组：与 `AttributeType` 一一对应。 | `[100, 50]` |
| **`AttributePValue`** | Array | 属性百分比数组：万分比修改（10000 = 100%）。 | `[2000, 0]` (加20%攻) |
| **`Duration`** | Number | 默认持续回合数。 | `2` (持续2回合) |

*(注：系统中的 `config/buff_config.lua` 会在启动时将这些 JSON 数据自动转化为内部的 `attribute` effect 以供底层计算)*

---

## 二、 动态行为配置 (`buff_{ID}.lua`)

动态配置位于 `config/buff/` 目录下（如 `buff_9001.lua`）。它负责定义 Buff 的**触发生命周期**以及那些无法通过简单修改面板属性来实现的**复杂效果（如 DOT、HOT、受击反伤等）**。

### 2.1 触发时机 (`timing` 枚举)
所有的动态效果都必须指定 `timing` 参数，决定该效果在战斗的哪一个时间节点被激活结算：

*   `1`: **ON_ADD** (获得瞬间触发，常用于一次性回血或加成)
*   `2`: **ON_REMOVE** (移除或时间到消失瞬间触发，常用于死后爆炸等)
*   `3`: **ON_ROUND_BEGIN** (大回合开始时触发，最适合 **HOT 持续治疗**或持续回能)
*   `4`: **ON_ROUND_END** (大回合结束时触发，最适合 **DOT 毒/流血伤害**)
*   `5`: **ON_ATTACK** (携带者发起攻击前触发)
*   `6`: **ON_DEFEND** (携带者被攻击前触发)
*   `7`: **ON_DAMAGE** (携带者造成伤害后触发，适合吸血)
*   `8`: **ON_RECEIVE_DAMAGE** (携带者受到伤害后触发，适合反伤或受击回血)
*   `11`: **ON_KILL** (击杀目标时触发)
*   `12`: **ON_DEATH** (自身死亡时触发)

### 2.2 效果类型 (`effects` 数组)
`effects` 是一个数组，每个元素都是一个包含了 `type` 和具体参数的字典。以下是系统支持的所有 `type` 及其详细参数说明：

#### 1. 持续伤害 / 反伤 (`damage`)
用于实现中毒、灼烧、流血或受击反弹伤害的效果。
*   **支持参数**：
    *   `value` (Number): 伤害数值倍率（通常为施法者攻击力的万分比）。
    *   `damageType` (Number): 伤害属性（`1`: 物理, `2`: 法术, `5`: 真实伤害）。
*   **配置示例**：
```lua
-- 灼烧：每回合结束造成 50% 的法术伤害
effects = {
    { type = "damage", timing = 4, value = 5000, damageType = 2 }
}
```

#### 2. 持续治疗 (`heal`)
用于实现 HOT (Heal Over Time) 效果。
*   **支持参数**：
    *   `value` (Number): 治疗基础数值倍率（施法者攻击力的万分比）。
    *   `percent` (Number, 可选): 如果配置此项，则按目标最大生命值的百分比进行恢复。
*   **配置示例**：
```lua
-- 回复：每回合开始恢复最大生命值的 10%
effects = {
    { type = "heal", timing = 3, percent = 1000 } -- 1000 = 10%
}
```

#### 3. 动态属性变更 (`attr_change`)
在特定时机动态修改单位属性（与静态 JSON 配置不同，这通常用于临时或条件触发的属性变化）。
*   **支持参数**：
    *   `attr` (Number): 属性 ID（参考 `E_ATTR`，如 `2` 为 ATK, `3` 为 DEF）。
    *   `value` (Number): 变更的数值（万分比，正数为增益，负数为减益）。
*   **配置示例**：
```lua
-- 狂暴：受到伤害后，临时提升 20% 攻击力
effects = {
    { type = "attr_change", timing = 8, attr = 2, value = 2000 }
}
```

#### 4. 能量控制 (`energy`)
用于增加或扣除大招能量（怒气）。
*   **支持参数**：
    *   `value` (Number): 能量变更的具体点数（支持正负）。
*   **配置示例**：
```lua
-- 振奋：击杀目标时额外恢复 20 点能量
effects = {
    { type = "energy", timing = 11, value = 20 }
}
```

#### 5. 驱散效果 (`dispel`)
在特定时机清除目标身上的其他 Buff 状态。
*   **支持参数**：
    *   `targetType` (Number): 驱散目标类型（`1`: 驱散正面增益, `2`: 驱散负面减益）。
*   **配置示例**：
```lua
-- 净化：获得该 Buff 的瞬间，清除自身所有减益状态
effects = {
    { type = "dispel", timing = 1, targetType = 2 }
}
```

#### 6. 完全自定义脚本 (`custom`)
用于实现上述预设类型无法覆盖的极度复杂机制。
*   **支持参数**：
    *   `func` (Function): 具体的 Lua 函数实现。该函数会接收 `(buff, hero, effect)` 三个参数。
*   **配置示例**：
```lua
-- 死亡时触发自定义的自爆全屏伤害逻辑
effects = {
    { 
        type = "custom", 
        timing = 12, -- ON_DEATH
        func = function(buff, hero, effect)
            Logger.Log(hero.name .. " 触发了死亡爆炸！")
            -- 寻找所有存活的敌方并执行伤害逻辑
            local enemies = BattleFormation.GetAliveEnemies(hero.camp)
            for _, enemy in ipairs(enemies) do
                BattleFormula.DirectDamage(hero, enemy, 9999)
            end
        end 
    }
}
```

---

## 三、 Buff 叠加规则 (`stackRule`)
在动态 Lua 脚本的顶层，可以覆盖静态 JSON 中的叠加规则：

*   **`refresh`**：重复获得相同 ID 的 Buff 时，层数增加（不超过 `MaxLimit`），并且**刷新**其持续回合数到初始值。这是最常用的状态叠加规则。
*   **`add`**：仅增加层数，但持续时间**不刷新**（或者各层独立计算时间，取决于底层具体实现）。
*   **`independent`**：允许同一个英雄身上同时存在多个完全相同 ID 的 Buff 实例，它们各自独立计算生命周期和效果。

---

## 四、 完整配置模板示例

为了便于理解，以下提供一个名为 **“魔王降临”** 的复合型 Buff 完整配置模板。
**Buff 设定**：
*   静态属性：增加 20% 攻击力和 10% 暴击率，持续 3 回合，最多叠加 2 层。
*   动态效果 1：获得时，立刻恢复自身 15% 的最大生命值。
*   动态效果 2：每回合结束时，流失 50 点固定生命值（代价）。
*   动态效果 3：自身死亡时，给全场敌方造成 500% 攻击力的爆炸伤害。

### 4.1 JSON 静态模板 (`res_buff_template.json` 截取)
```json
{
    "ID": 9005,
    "Name": "魔王降临",
    "MainType": 1,              // 1: 增益
    "SubType": 105,             // 自定义子类型
    "StackType": 1,             // 1: 刷新持续时间
    "MaxLimit": 2,              // 最多叠加 2 层
    "DispelGroup": 2,           // 驱散优先级为 2
    "Duration": 3,              // 持续 3 回合
    
    // 面板属性直接修改
    "AttributeType": [2, 5],    // 2: ATK(攻击), 5: CRIT_RATE(暴击率)
    "AttributePValue": [2000, 1000] // 增加 20% 攻击，10% 暴击
}
```

### 4.2 Lua 动态脚本 (`config/buff/buff_9005.lua`)
```lua
-- Buff 9005: 魔王降临 动态逻辑
local buff_9005 = {
    -- 叠加规则：刷新时间并叠加层数（覆盖或补充 JSON 配置）
    stackRule = "refresh",
    
    effects = {
        -- 效果 1：获得瞬间 (ON_ADD)，恢复 15% 最大生命值
        {
            type = "heal",
            timing = 1, -- 1: ON_ADD
            percent = 1500 -- 1500 = 15%
        },
        
        -- 效果 2：每回合结束 (ON_ROUND_END)，流失固定生命值（也可以配置为真实伤害）
        {
            type = "damage",
            timing = 4, -- 4: ON_ROUND_END
            value = 50, -- 固定 50 点
            damageType = 5 -- 5: 真实伤害/生命流失
        },
        
        -- 效果 3：死亡时 (ON_DEATH)，触发自定义全屏爆炸
        {
            type = "custom",
            timing = 12, -- 12: ON_DEATH
            func = function(buff, hero, effect)
                -- 获取战场中存活的敌方
                local enemies = BattleFormation.GetAliveEnemies(hero.camp)
                
                -- 计算爆炸伤害：施法者死亡前攻击力的 500%
                local explodeDmgRate = 50000 
                
                for _, enemy in ipairs(enemies) do
                    -- 调用核心公式进行伤害结算
                    BattleFormula.CalcDamage(hero, enemy, explodeDmgRate, nil)
                end
                
                -- 可选：通过抛出事件让表现层播放一个爆炸特效
                BattleEvent.Dispatch(BattleEvent.EVENT_PLAY_EFFECT, {
                    effectName = "eff_demon_explode",
                    pos = hero.pos
                })
            end
        }
    }
}

return buff_9005
```