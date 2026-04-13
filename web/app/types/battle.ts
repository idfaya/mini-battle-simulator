export type TeamSide = "left" | "right";

export type BuffState = {
  buffId: number;
  name: string;
  stackCount: number;
  duration: number;
};

export type UnitState = {
  id: string;
  name: string;
  team: TeamSide;
  position: number;
  hp: number;
  maxHp: number;
  energy: number;
  maxEnergy: number;
  isAlive: boolean;
  buffs: BuffState[];
  ultimateReady: boolean;
  ultimateSkillName: string;
};

export type BattleResult = {
  winner: "left" | "right" | "draw";
  reason: string;
};

export type BattleSnapshot = {
  phase: "running" | "ended";
  round: number;
  activeHeroId: string | null;
  leftTeam: UnitState[];
  rightTeam: UnitState[];
  pendingCommands: number;
  result: BattleResult | null;
};

export type BattleEvent = {
  type: string;
  ts: number;
  payload: Record<string, unknown>;
};

export type BattleCommand = {
  type: "cast_ultimate";
  heroId: string;
};

export type AnimationEvent =
  | { type: "damage"; heroId: string; value: number; critical: boolean }
  | { type: "heal"; heroId: string; value: number }
  | { type: "banner"; text: string; emphasis?: boolean };
