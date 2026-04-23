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
  classId: number;
  className: string;
  classIcon: string;
  hp: number;
  maxHp: number;
  speed: number;
  ac: number;
  hit: number;
  spellDC: number;
  saveFort: number;
  saveRef: number;
  saveWill: number;
  energy: number;
  maxEnergy: number;
  ultimateCharges: number;
  ultimateChargesMax: number;
  isAlive: boolean;
  isChanting: boolean;
  pendingSkillName: string | null;
  isConcentrating: boolean;
  concentrationSkillId: number | null;
  concentrationSkillName: string | null;
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

export type BattleSetup = {
  level: number;
  heroCount: number;
  enemyCount: number;
  initialEnergy: number;
  speed: number;
};

export type AnimationEvent =
  | { type: "damage"; heroId: string; value: number; critical: boolean }
  | { type: "heal"; heroId: string; value: number }
  | { type: "banner"; text: string; emphasis?: boolean }
  | {
      type: "timeline_started";
      heroId: string;
      heroName: string;
      skillName: string;
      totalFrames: number;
    }
  | {
      type: "timeline_frame";
      heroId: string;
      heroName: string;
      skillName: string;
      frame: number;
      frameIndex: number;
      op: string;
      effect: string;
      targetIds: string[];
    }
  | {
      type: "timeline_completed";
      heroId: string;
      heroName: string;
      skillName: string;
      totalFrames: number;
      totalDamage: number;
      succeeded: boolean;
    };
