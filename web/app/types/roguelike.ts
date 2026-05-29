import type { BattleCommand, BattleEvent, BattleSnapshot } from "./battle";

export type RunPhase =
  | "map"
  | "battle"
  | "event"
  | "shop"
  | "camp"
  | "stair"
  | "reward"
  | "chapter_result"
  | "failed";

export type RunNodeType =
  | "battle_normal"
  | "battle_elite"
  | "event"
  | "shop"
  | "camp"
  | "boss"
  | "recruit"
  | "equip"
  | "empty"
  | "stair_up"
  | "stair_down";

export type RunMapNodeState = {
  id: number;
  floor: number;
  lane: number;
  gridX?: number;
  gridY?: number;
  floorGridW?: number;
  floorGridH?: number;
  nodeType: RunNodeType;
  isHiddenFloor?: boolean;
  title: string;
  visited: boolean;
  current: boolean;
  selectable: boolean;
  revealed: boolean;
  titleVisible: boolean;
  nextNodeIds: number[];
};

export type RunMapEdgeState = {
  fromNodeId: number;
  toNodeId: number;
};

export type RunMapState = {
  chapterId: number;
  floorCount: number;
  startNodeId: number;
  bossNodeId: number;
  nodes: RunMapNodeState[];
  edges: RunMapEdgeState[];
};

export type RunTeamMember = {
  rosterId?: number;
  unitId?: string;
  heroId: number;
  name: string;
  classId: number;
  className?: string;
  characterGroup?: "physical" | "caster";
  level: number;
  exp?: number;
  nextLevelExp?: number;
  star: number;
  hp: number;
  maxHp: number;
  isDead: boolean;
  teamState?: "active" | "bench" | "dead";
  skillPackageId?: string;
  buildSummary?: string[];
  str?: number;
  dex?: number;
  con?: number;
  int?: number;
  wis?: number;
  cha?: number;
  strMod?: number;
  dexMod?: number;
  conMod?: number;
  intMod?: number;
  wisMod?: number;
  chaMod?: number;
  ac?: number;
  hit?: number;
  spellAttack?: number;
  spellDC?: number;
  saveFort?: number;
  saveRef?: number;
  saveWill?: number;
  weaponDice?: string;
};

export type EquipmentState = {
  equipmentId: number;
  name: string;
  rarity: string;
  code: string;
  slot?: string;
  slotLabel?: string;
  effectType?: string;
  effectDescription?: string;
  classScope?: string;
};

export type BlessingState = {
  blessingId: number;
  name: string;
  rarity: string;
  code: string;
  description?: string;
};

export type RewardOption = {
  rewardType: "gold" | "equipment" | "blessing" | "recruit";
  refId?: number;
  value?: number;
  label: string;
  description: string;
  rarity?: string;
  resultType?: "new_class_unit" | "class_promotion";
  teamState?: "active" | "bench" | "dead";
  summaryKey?: string;
};

// 队伍升级三选一选项（kind="feat_levelup"），来自 roguelike/feat_picker.lua。
export type FeatOption = {
  featId: number;
  heroId: number;
  rosterId?: number;
  heroName: string;
  classId: number;
  level: number;
  tier: "small" | "medium" | "high";
  isSubclassCore: boolean;
  featName?: string;
  featDescription?: string;
  choiceGroup?: string | null;
};

export type RewardState =
  | {
      groupId: number;
      kind: "feat_levelup";
      options: FeatOption[];
      pendingLevels: number;
    }
  | {
      groupId: number;
      kind: string;
      options: RewardOption[];
    };

export type BattleLevelUpStatChange = {
  key: string;
  label: string;
  format: "flat" | "bp_pct";
  delta: number;
  before: number;
  after: number;
};

export type BattleLevelUpFeatGain = {
  featId: number;
  name: string;
  description: string;
};

export type BattleLevelUpSkillCard = {
  skillId: number;
  name: string;
  runtimeKind: "active" | "passive";
};

export type BattleLevelUpSummary = {
  rosterId: number;
  unitId?: string;
  heroName: string;
  classId: number;
  levelBefore: number;
  levelAfter: number;
  statChanges: BattleLevelUpStatChange[];
  gainedFeats: BattleLevelUpFeatGain[];
  gainedSkillCards?: BattleLevelUpSkillCard[];
};

export type LastBattleSummary = {
  won: boolean;
  earnedGold: number;
  expReward?: number;
  equipmentDropCount?: number;
  battleNodeId?: number;
  levelUps?: BattleLevelUpSummary[];
  result?: {
    winner?: string;
    reason?: string;
  };
};

export type EventSkillCheckState = {
  ability: string;
  dc: number;
};

export type EventSkillCheckOutcomeState = {
  ability?: string;
  roll?: number;
  modifier?: number;
  total?: number;
  dc?: number;
  tier?: string;
  heroName?: string;
};

export type EventOptionState = {
  id: number;
  label: string;
  costType?: string;
  costValue?: number;
  zeroRisk?: boolean;
  skillCheck?: EventSkillCheckState;
};

export type EventResultState = {
  title: string;
  optionLabel?: string;
  summary: string;
  details: string[];
  actionLabel: string;
};

export type EventState = {
  id: number;
  chapterId: number;
  code: string;
  title: string;
  kind: string;
  options: EventOptionState[];
  lastSkillCheck?: EventSkillCheckOutcomeState | null;
  result?: EventResultState | null;
};

export type ShopGoodsState = {
  goodsId: number;
  goodsType: string;
  refId?: number;
  code?: string;
  name: string;
  description?: string;
  price: number;
  rarity: string;
  sold: boolean;
};

export type ShopState = {
  shopId: number;
  name: string;
  refreshCost: number;
  refreshCount: number;
  maxRefresh: number;
  goods: ShopGoodsState[];
};

export type CampActionState = {
  id: number;
  label: string;
  available: boolean;
};

export type CampState = {
  campId: number;
  name: string;
  actions: CampActionState[];
};

export type StairState = {
  direction: "up" | "down";
  nodeId: number;
  currentFloorDepth?: number | null;
  isHiddenEntrance?: boolean;
};

export type TrinketState = {
  trinketId: number;
  name: string;
  rarity: string;
  code: string;
  description?: string;
};

export type ChapterResult = {
  success: boolean;
  reason: string;
  gold?: number;
  equipmentCount?: number;
  blessingCount?: number;
  trinketCount?: number;
};

export type RunSnapshot = {
  phase: RunPhase;
  chapterId: number;
  currentFloorDepth?: number | null;
  hiddenFloorInjected?: boolean;
  hiddenFloorActive?: boolean;
  hiddenFloorCleared?: boolean;
  hiddenFloorStairRoomId?: number | null;
  currentNodeId: number | null;
  maxHeroCount: number;
  partyLevel: number;
  partyExp: number;
  levelProgressExp: number;
  nextLevelExp: number;
  gold: number;
  food: number;
  lastActionMessage: string;
  map: RunMapState | null;
  team: RunTeamMember[];
  bench: RunTeamMember[];
  equipments: EquipmentState[];
  blessings: BlessingState[];
  trinkets?: TrinketState[];
  eventState: EventState | null;
  shopState: ShopState | null;
  campState: CampState | null;
  stairState: StairState | null;
  rewardState: RewardState | null;
  lastBattleSummary?: LastBattleSummary | null;
  battleSnapshot: BattleSnapshot | null;
  chapterResult: ChapterResult | null;
  debug: {
    availableNextNodeIds: number[];
  };
};

export type RunActionResponse = {
  accepted: boolean;
  reason?: string;
};

export type RunTickResult = {
  events: BattleEvent[];
  snapshot: RunSnapshot;
};

export type RunBattleCommand = BattleCommand;
