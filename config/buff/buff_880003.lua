local buff_880003 = {
    buffId = 880003,
    mainType = E_BUFF_MAIN_TYPE.CONTROL,
    subType = E_BUFF_SPEC_SUBTYPE.STUN,
    name = "眩晕",
    initialStack = 1,
    maxStack = 1,
    duration = 1,
    canStack = false,
    stackRule = "refresh",
    effects = {}
}

return {
    buff_880003 = buff_880003
}
