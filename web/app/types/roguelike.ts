import type { BattleCommand, BattleEvent, BattleSnapshot } from "./battle";

export type RunPhase =
  | "map"
  | "battle"
  | "event"
  | "shop"
  | "camp"
  | "reward"
  | "chapter_result"
  | "failed";

export type RunNodeType = "battle_normal" | "battle_elite" | "event" | "shop" | "camp" | "boss" | "recruit";

export type RunMapNodeState = {
  id: number;
  floor: number;
  lane: number;
  nodeType: RunNodeType;
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
  promotionStage?: "low" | "mid" | "high";
  skillPackageId?: string;
  buildSummary?: string[];
};

export type EquipmentState = {
  equipmentId: number;
  name: string;
  rarity: string;
  code: string;
};

export type BlessingState = {
  blessingId: number;
  name: string;
  rarity: string;
  code: string;
  description?: string;
};

export type RewardOption = {
  rewardType: "gold" | "equipment" | "blessing" | "recruit" | "levelup";
  refId?: number;
  value?: number;
  label: string;
  description: string;
  resultType?: "new_class_unit" | "class_promotion";
  teamState?: "active" | "bench" | "dead";
  promotionStageBefore?: "low" | "mid" | "high";
  promotionStageAfter?: "low" | "mid" | "high";
  summaryKey?: string;
  // Level-up composite card (battle_levelup)
  rosterId?: number;
  heroName?: string;
  classId?: number;
  nextLevel?: number;
  featId?: number;
  featName?: string;
  featCode?: string;
  featTags?: string[];
};

export type RewardState = {
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
  promotionStageBefore?: "low" | "mid" | "high";
  promotionStageAfter?: "low" | "mid" | "high";
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

export type EventOptionState = {
  id: number;
  label: string;
  costType?: string;
  costValue?: number;
};

export type EventState = {
  id: number;
  chapterId: number;
  code: string;
  title: string;
  kind: string;
  options: EventOptionState[];
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

export type ChapterResult = {
  success: boolean;
  reason: string;
  gold?: number;
  equipmentCount?: number;
  blessingCount?: number;
};

export type RunSnapshot = {
  phase: RunPhase;
  chapterId: number;
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
  eventState: EventState | null;
  shopState: ShopState | null;
  campState: CampState | null;
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
