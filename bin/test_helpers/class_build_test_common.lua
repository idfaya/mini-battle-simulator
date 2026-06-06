local M = {}

function M.bootstrapFromCaller(script_source)
    local script_path = script_source:sub(2)
    local script_dir = script_path:match("(.*[/\\])") or "./"
    local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
    LuaBootstrap.SetupFromSource(script_source, { includeParent = true })
    return script_dir
end

function M.makeAssert()
    local function log(msg)
        print(msg)
    end
    local function assert_true(cond, name)
        if not cond then
            io.stderr:write("ASSERT FAIL: " .. name .. "\n")
            os.exit(1)
        else
            log("ASSERT OK  : " .. name)
        end
    end
    return assert_true, log
end

function M.canonicalSelections(ClassBuildProgression, classId, toLevel)
    local lv1Set = {}
    for _, fid in ipairs(ClassBuildProgression.GetLv1FeatIds(classId)) do
        lv1Set[tonumber(fid) or 0] = true
    end
    local selections = {}
    for _, fid in ipairs(ClassBuildProgression.GetCanonicalFeatChain(classId, toLevel)) do
        if not lv1Set[tonumber(fid) or 0] then
            selections[#selections + 1] = fid
        end
    end
    return selections
end

function M.hasSkill(list, skillId)
    for _, entry in ipairs(list or {}) do
        if tonumber(entry.id or entry.skillId) == tonumber(skillId) then
            return true
        end
    end
    return false
end

function M.findSkill(list, skillId)
    for _, entry in ipairs(list or {}) do
        if tonumber(entry.id or entry.skillId) == tonumber(skillId) then
            return entry
        end
    end
    return nil
end

function M.newUnit(id, name, classId, wpType)
    return {
        id = id,
        instanceId = id,
        name = name,
        hp = 100,
        maxHp = 100,
        isDead = false,
        isAlive = true,
        isLeft = true,
        skills = {},
        skillsConfig = {},
        skillData = nil,
        wpType = wpType or 4,
        class = classId or 3,
        classId = classId or 3,
    }
end

return M
