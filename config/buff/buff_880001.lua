local buff_880001 = {
    buffId = 880001,
    mainType = E_BUFF_MAIN_TYPE.BAD,
    subType = 880001,
    name = "减速",
    initialStack = 1,
    maxStack = 1,
    value = 3000,
    maxValue = 3000,
    displayMode = "pct",
    duration = 2,
    canStack = false,
    stackRule = "refresh",
    effects = {}
}

return {
    buff_880001 = buff_880001
}
