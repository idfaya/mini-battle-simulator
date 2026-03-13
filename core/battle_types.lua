---
--- Battle Default Types
--- Copied from Assets/Lua/Modules/Battle/BattleDefaultTypes.lua
---

Vector3_Default = {
	x = 0,
	y = 0,
	z = 0
}

Quaternion_Default = {
	x = 0,
	y = 0,
	z = 0,
	w = 1
}

BezierControlPoint_Default = {
	point = Vector3_Default,
	leftTangent = Vector3_Default,
	rightTangent = Vector3_Default,
	quaternion = Quaternion_Default,
	mode = 0,
}

PreContidion_Default = {
	FunctionName = "",
}

TSFilter_Default = {
	conditionFilter = 0,
	conditionFilterDirection = 0,
	PropertyID = 1,
	BuffSubType = 0,
	wpType = 0,
	buffMainType = 0,
}

TSConditions_Default = {
	measureType = 0,
	buffSubType = 0,
	heroId = 0,
	conditionDirection = 0,
	Num = 0,
	autoFullNum = false,
	tSFilter = TSFilter_Default,
}

TargetsSelections_Default = {
	castTarget = 0,
	markForDel = false,
	tSConditions = TSConditions_Default,
	NoInheritWhenEmpty = false,
}

ParamData_Default = {
	ID = 0,
	Param = 0,
}

CameraData_Default = {
	preCondition = PreContidion_Default,
	triggerS = 0,
	IsShake = false,
	CameraShakeName = "",
	clipduring = 0,
}

SoundData_Default = {
	preContidion = PreContidion_Default,
	soundid = "",
	triggerS = 0,
	duringS = 0,
}

FieldData_Default = {
	placeType = 0,
}

BoneData_Default = {
	AttachType = 0,
	BoneName = "",
	RelativePoint = 0,
	RelativePointName = "",
	fieldData = FieldData_Default,
	offset = Vector3_Default,
}

EffectData_Default = {
	preCondition = PreContidion_Default,
	effectpath = "",
	appearAnimPath = "",
	disappearAnimPath = "",
	soundData = SoundData_Default,
	triggerS = 0,
	duringS = 0,
	target = 2,
	binding = 0,
	scale = Vector3_Default,
	BoneData = BoneData_Default,
	ArenaCoordinate = Vector3_Default,
	fieldData = FieldData_Default,
}

VariableParamData_Default = {
	IDS = {},
}

DamageData_Default = {
	damageType = 1,
	attackType = 1,
	cSVSkillAssociate = 0,
	hitType = 0,
	attr = 0,
	Sender = VariableParamData_Default,
	Target = VariableParamData_Default,
}

HealData_Default = {
	attributeType = 9,
	healType = 0,
	cSVSkillAssociate = 0,
	Sender = VariableParamData_Default,
	Target = VariableParamData_Default,
}

DispelData_Default = {
	associate = 0,
	primaryType = 0,
}

EnergyData_Default = {
	cSVSkillAssociate = 0,
	energyDataType = 0,
}

ActionforceData_Default = {
	cSVSkillAssociate = 0,
}

LaunchBuff_Default = {
	preContidion = PreContidion_Default,
	targetsSelections = TargetsSelections_Default,
	AssociateBuff = 0,
}

LuaData_Default = {
	preCondition = PreContidion_Default,
	triggerS = 0,
	DuringS = 0,
	LuaName = "",
	FunctionName = "",
}

ActConditionn_Default = {
	campType = 0,
	NotU1 = false,
}

CartoonData_Default = {
	animationname = "",
	animationPath = "",
	animatorname = "",
	during = 0,
	triggerS = 0,
	TotalS = 0,
	targetsSelections = TargetsSelections_Default,
}

LaunchMove_Default = {
	MoveID = 0,
	isMoveBack = false,
	triggerTimeS = 0,
	MLimitTimeS = 1,
	moveOffsetDis = 0,
}

VideoData_Default = {
	videoPath = "",
	during = 0,
	closeTimeS = 0,
	soundData = SoundData_Default,
}

KeyFramesNew_Default = {
	contidion = PreContidion_Default,
	targetsSelections = TargetsSelections_Default,
	TriggerS = 0,
	DuringS = 0,
	datatype = "",
	data = "",
}

ActDataNew_Default = {
	actConditionn = ActConditionn_Default,
	contidion = PreContidion_Default,
	targetsSelections = TargetsSelections_Default,
	atLeastTimeS = 0,
	cartoon = CartoonData_Default,
	LaunchMove = LaunchMove_Default,
	VideoData = VideoData_Default,
	keyFrameDatas = {},
}

MoveTemplate_Default = {
	MotionType = 0,
	mCurveTypeData = "",
	mCurveArray = "",
	factorx = 0,
	factory = 0,
	factorz = 0,
	mTopHeight = 0,
	mCurveGravityData = "",
	mCurveGravityArray = "",
	mBezierPoints = {},
}

BuffTemplateShow_Default = {
	SEIntervals = EffectData_Default,
	SEstart = EffectData_Default,
	SDstart = SoundData_Default,
	SEloop = EffectData_Default,
	SEend = EffectData_Default,
	SDend = SoundData_Default,
	ChgModelInfo = {},
	HideChgModelInfo = {},
}

AttackDrop_Default = {
	targetsSelections = TargetsSelections_Default,
	preContidion = PreContidion_Default,
	triggerType = 0,
	damageData = DamageData_Default,
	healData = HealData_Default,
	dispelData = DispelData_Default,
	energyData = EnergyData_Default,
	actionforceData = ActionforceData_Default,
}

SpellTemplate_Default = {
	MotionType = 0,
	IsMoveToTarget = false,
	flip = false,
	MoveID = 0,
	MotionEffectPath = "",
	IsHitExplosion = true,
	IntervalTimeS = 1,
	Trigger = AttackDrop_Default,
	TargetEffect = EffectData_Default,
	SoundData = SoundData_Default,
	VoiceData = SoundData_Default,
	launchBuff = LaunchBuff_Default,
	CameraData = {},
	NewAttackDrop = AttackDrop_Default,
	NewHitDuringTimeS = 0,
	NewIntervalTimeS = 0,
}

SkillTemplateNew_Default = {
	Class = 0,
	targetsSelections = TargetsSelections_Default,
	seqAsTarget = false,
	extraTargetsSelections = {},
	LuaFile = "",
	actData = {},
	keepRotation = false,
}

UnitEventTrigger_Default = {
	triggerTime = 0,
	luaFuncName = "",
}

UnitEventTemplate_Default = {
	eventid = 0,
	LuaFile = "",
	triggers = {},
	targetsSelection = TargetsSelections_Default,
}

BattleCArrayName2Type = {
	["IDS"] = ParamData_Default,
	["keyFrameDatas"] = KeyFramesNew_Default,
	["mBezierPoints"] = BezierControlPoint_Default,
	["ChgModelInfo"] = BoneData_Default,
	["HideChgModelInfo"] = BoneData_Default,
	["CameraData"] = CameraData_Default,
	["extraTargetsSelections"] = TargetsSelections_Default,
	["actData"] = ActDataNew_Default,
	["triggers"] = UnitEventTrigger_Default,
}

-- Return a dummy table since this module only defines global defaults
return {}
