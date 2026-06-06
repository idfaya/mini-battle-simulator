-- 兼容入口：按职业拆分的构建管线测试聚合运行器。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"

local suites = {
    "test_monk_build_pipeline.lua",
    "test_paladin_build_pipeline.lua",
    "test_barbarian_build_pipeline.lua",
    "test_ranger_build_pipeline.lua",
    "test_rogue_build_pipeline.lua",
    "test_cleric_build_pipeline.lua",
    "test_class_build_shared.lua",
}

for _, name in ipairs(suites) do
    dofile(script_dir .. name)
end

print("All class build pipeline suites passed.")
