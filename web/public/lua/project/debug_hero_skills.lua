package.path = './?.lua;./config/?.lua;./modules/?.lua;./core/?.lua;./utils/?.lua'
require('core.battle_enum')
require('modules.BattleDefaultTypesOpt')

local SRC = require('config.skill_rgl_config')
SRC.Init()
local RH = require('config.rgl_hero_data')

-- Debug: check what GetSkillLevels returns for key ClassIDs
print("=== GetSkillLevels Debug ===")
for _, cid in ipairs({8000101, 8000102, 8000103, 8000104, 8000110, 8000120}) do
    local levels = SRC.GetSkillLevels(cid)
    print(string.format("ClassID %d -> %d levels found:", cid, #levels))
    for _, l in ipairs(levels) do
        print(string.format("  ID=%d Level=%d Type=%d Name=%s", l.ID, l.SkillLevel, l.Type, l.Name))
    end
end

print("\n=== Hero Skills ===")
for _, id in ipairs({900001, 900002, 900003, 900004, 900005, 900006, 900007, 900008}) do
    local h = RH.ConvertToHeroData(id, 50, 5)
    if h then
        print(h.name .. ':')
        for i, c in ipairs(h.skillsConfig) do
            local cfg = SRC.GetSkillConfig(c.skillId)
            print(string.format("  [%d] skillId=%d classId=%d type=%s cost=%d | GetSkillConfig=%s Type=%d Name=%s",
                i, c.skillId, c.classId,
                c.skillType == 1 and 'NORMAL' or c.skillType == 2 and 'ACTIVE' or c.skillType == 3 and 'ULTIMATE' or c.skillType == 4 and 'PASSIVE' or 'OTHER('..c.skillType..')',
                c.skillCost,
                cfg and 'FOUND' or 'NIL',
                cfg and cfg.Type or -1,
                cfg and cfg.Name or '-'))
        end
        print('')
    end
end
