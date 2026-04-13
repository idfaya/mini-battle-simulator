local buff_880002 = {
    buffId = 880002,
    mainType = E_BUFF_MAIN_TYPE.CONTROL,
    subType = E_BUFF_SPEC_SUBTYPE.Frozen,
    name = "冻结",
    initialStack = 1,
    maxStack = 1,
    duration = 1,
    canStack = false,
    stackRule = "refresh",
    effects = {}
}

return {
    buff_880002 = buff_880002
}
