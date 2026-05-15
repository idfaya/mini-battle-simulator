local buff_880005 = {
    buffId = 880005,
    mainType = E_BUFF_MAIN_TYPE.BAD,
    subType = 880005,
    name = "霜冻",
    initialStack = 1,
    maxStack = 1,
    duration = 2,
    canStack = false,
    stackRule = "refresh",
    desc = "无法移动，但仍可进行远程攻击和释放技能。",
}

return {
    buff_880005 = buff_880005
}
