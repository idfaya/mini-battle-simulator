import {
  formatDamageRoll,
  formatTopBarCheckSuffix,
  normalizeTopBarCheckText,
} from "./rollFormat";

export type TopBarBriefs = {
  skillBrief: string | null;
  damageBrief: string | null;
};

export function buildSkillCheckBrief(payload: Record<string, unknown>): string | null {
  const skillName = String(payload.skillName ?? "").trim();
  const rollSuffix = formatTopBarCheckSuffix(payload);
  if (!skillName && !rollSuffix) {
    return null;
  }
  if (!skillName) {
    return rollSuffix.trim();
  }
  return `${skillName}${rollSuffix}`.trim();
}

export function buildDamageBriefFromPayload(payload: Record<string, unknown>): string | null {
  return formatDamageRoll(payload.damageRoll);
}

export function buildTopBarBriefsFromPayload(
  payload: Record<string, unknown>,
  options?: { includeDamage?: boolean },
): TopBarBriefs {
  return {
    skillBrief: buildSkillCheckBrief(payload),
    damageBrief: options?.includeDamage === false ? null : buildDamageBriefFromPayload(payload),
  };
}

const MULTI_TARGET_SKILL_MARKERS = [
  " 攻击检定",
  " 强韧豁免",
  " 反射豁免",
  " 意志豁免",
  " 豁免豁免",
  " 治疗 ",
] as const;

export function annotateMultiTargetSkillBrief(skillBrief: string, hitIndex: number): string {
  if (hitIndex <= 1) {
    return skillBrief;
  }
  for (const marker of MULTI_TARGET_SKILL_MARKERS) {
    const markerIndex = skillBrief.indexOf(marker);
    if (markerIndex > 0) {
      return `${skillBrief.slice(0, markerIndex)} ·${hitIndex}${skillBrief.slice(markerIndex)}`;
    }
  }
  return `${skillBrief} ·${hitIndex}`;
}

export function withMultiTargetAnnotation(briefs: TopBarBriefs, hitIndex: number): TopBarBriefs {
  if (!briefs.skillBrief || hitIndex <= 1) {
    return briefs;
  }
  return {
    ...briefs,
    skillBrief: annotateMultiTargetSkillBrief(briefs.skillBrief, hitIndex),
  };
}

function splitRollText(rollText: string) {
  const parts = rollText
    .split("；")
    .map((part) => part.trim())
    .filter(Boolean);
  const damageParts = parts.filter((part) => part.includes("伤害骰"));
  const checkParts = parts.filter((part) => !part.includes("伤害骰"));
  return {
    checkText: checkParts.join("；"),
    damageText: damageParts.length > 0 ? damageParts.join("；") : null,
  };
}

export function extractTopBarBriefsFromCombatLog(message: string): TopBarBriefs | null {
  const useMarker = " 使用 ";
  const useIdx = message.indexOf(useMarker);
  const colonIdx = message.indexOf("：", useIdx);
  if (useIdx < 0 || colonIdx <= useIdx) {
    return null;
  }
  const skillName = message.slice(useIdx + useMarker.length, colonIdx).trim();
  const rollStart = message.lastIndexOf("（");
  if (rollStart < 0 || !message.endsWith("）")) {
    return skillName ? { skillBrief: skillName, damageBrief: null } : null;
  }
  const rollText = message.slice(rollStart + 1, -1);
  const { checkText, damageText } = splitRollText(rollText);
  const skillBrief = checkText ? `${skillName} ${normalizeTopBarCheckText(checkText)}`.trim() : skillName;
  return {
    skillBrief: skillBrief || null,
    damageBrief: damageText,
  };
}

