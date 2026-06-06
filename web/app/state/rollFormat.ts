export function formatSigned(value: number) {
  return value >= 0 ? `+${value}` : String(value);
}

export function readNumber(value: unknown, fallback = 0) {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : fallback;
}

function readRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null ? (value as Record<string, unknown>) : null;
}

const SAVE_TYPE_LABELS: Record<string, string> = {
  fort: "强韧",
  ref: "反射",
  will: "意志",
};

function formatSaveOutcome(success: boolean, onSaveSuccess: unknown) {
  if (!success) {
    return "失败";
  }
  if (onSaveSuccess === "half") {
    return "成功（半伤）";
  }
  if (onSaveSuccess === "none") {
    return "成功（无伤）";
  }
  return "成功";
}

function isAttackCrit(roll: Record<string, unknown>, isCritOverride?: unknown) {
  if (isCritOverride === true) {
    return true;
  }
  return roll.crit === true || roll.nat20 === true;
}

function formatAttackOutcome(roll: Record<string, unknown>, isCritOverride?: unknown) {
  const hit =
    typeof roll.hit === "boolean"
      ? roll.hit
      : readNumber(roll.total) >= readNumber(roll.targetAC);
  if (!hit) {
    return "失败";
  }
  return isAttackCrit(roll, isCritOverride) ? "成功 暴击" : "成功";
}

export function formatCheckRoll(
  value: unknown,
  options?: {
    saveType?: unknown;
    onSaveSuccess?: unknown;
  },
) {
  const roll = readRecord(value);
  if (!roll) {
    return null;
  }

  const d20 = readNumber(roll.roll);
  const bonus = readNumber(roll.bonus);
  const total = readNumber(roll.total);
  if ("targetAC" in roll) {
    return `攻击检定 d20 ${d20}${formatSigned(bonus)}=${total} vs AC ${readNumber(roll.targetAC)}`;
  }
  if ("dc" in roll) {
    const label = SAVE_TYPE_LABELS[String(options?.saveType ?? "")] ?? "豁免";
    const outcome = formatSaveOutcome(Boolean(roll.success), options?.onSaveSuccess);
    return `${label}豁免${outcome} d20 ${d20}${formatSigned(bonus)}=${total} vs DC ${readNumber(roll.dc)}`;
  }
  return null;
}

export function mergeDamageRolls(primary: unknown, secondary: unknown): Record<string, unknown> | null {
  const left = readRecord(primary);
  const right = readRecord(secondary);
  if (!left) {
    return right;
  }
  if (!right) {
    return left;
  }
  const leftParts = Array.isArray(left.parts) ? left.parts : [];
  const rightParts = Array.isArray(right.parts) ? right.parts : [];
  const leftExpr = String(left.expr ?? "").trim();
  const rightExpr = String(right.expr ?? "").trim();
  const expr = [leftExpr, rightExpr].filter(Boolean).join(leftExpr && rightExpr ? ";" : "");
  return {
    ...left,
    ...right,
    expr: expr || left.expr || right.expr || "dice",
    parts: [...leftParts, ...rightParts],
    total: readNumber(left.total) + readNumber(right.total),
    scaledTotal: readNumber(left.scaledTotal ?? left.total) + readNumber(right.scaledTotal ?? right.total),
    crit: left.crit === true || right.crit === true,
  };
}

export function isSkillColoredDamagePayload(payload: Record<string, unknown>) {
  return payload.preferSkillColor === true || payload.isBasicAttack !== true;
}

export function shouldMergeDamagePayload(previous: Record<string, unknown>, current: Record<string, unknown>) {
  if (String(previous.targetId ?? "") !== String(current.targetId ?? "")) {
    return false;
  }
  if (String(previous.attackerId ?? "") !== String(current.attackerId ?? "")) {
    return false;
  }
  const previousBasic = previous.isBasicAttack === true;
  const currentBasic = current.isBasicAttack === true;
  if (!previousBasic && !currentBasic) {
    return false;
  }
  return (
    (previousBasic && isSkillColoredDamagePayload(current)) ||
    (currentBasic && isSkillColoredDamagePayload(previous))
  );
}

export function mergeDamageEventPayload(
  previous: Record<string, unknown>,
  current: Record<string, unknown>,
): Record<string, unknown> {
  return {
    ...previous,
    ...current,
    damage: readNumber(previous.damage) + readNumber(current.damage),
    damageRoll: mergeDamageRolls(previous.damageRoll, current.damageRoll),
    isCrit: Boolean(previous.isCrit) || Boolean(current.isCrit),
    isBasicAttack: Boolean(previous.isBasicAttack) || Boolean(current.isBasicAttack),
    preferSkillColor: Boolean(previous.preferSkillColor) || Boolean(current.preferSkillColor),
    skillName: String(current.skillName || previous.skillName || ""),
    skillId: current.skillId ?? previous.skillId,
    attackRoll: previous.attackRoll ?? current.attackRoll,
    saveRoll: previous.saveRoll ?? current.saveRoll,
    saveType: previous.saveType ?? current.saveType,
    onSaveSuccess: previous.onSaveSuccess ?? current.onSaveSuccess,
  };
}

export function formatDamageRoll(value: unknown) {
  const roll = readRecord(value);
  if (!roll) {
    return null;
  }

  const parts = Array.isArray(roll.parts) ? roll.parts : [];
  const partText = parts
    .map((part) => {
      const partRecord = readRecord(part);
      if (!partRecord) {
        return "";
      }
      const rolls = Array.isArray(partRecord.rolls) ? partRecord.rolls.map((item) => String(item)).join(",") : "";
      const bonus = readNumber(partRecord.bonus);
      return `[${rolls}]${bonus !== 0 ? formatSigned(bonus) : ""}`;
    })
    .filter(Boolean)
    .join(";");
  const expr = String(roll.expr ?? "dice");
  const total = readNumber(roll.total);
  return `伤害骰 ${expr}${partText ? ` ${partText}` : ""}=${total}`;
}

function formatTopBarCheckRoll(
  value: unknown,
  options?: {
    saveType?: unknown;
    onSaveSuccess?: unknown;
    isCrit?: unknown;
  },
) {
  const roll = readRecord(value);
  if (!roll) {
    return null;
  }

  const d20 = readNumber(roll.roll);
  const bonus = readNumber(roll.bonus);
  const total = readNumber(roll.total);
  const rollResult = `[${d20}]${formatSigned(bonus)} =${total}`;
  if ("targetAC" in roll) {
    const outcome = formatAttackOutcome(roll, options?.isCrit);
    return `攻击检定 d20${formatSigned(bonus)} vs AC${readNumber(roll.targetAC)} ${rollResult} ${outcome}`;
  }
  if ("dc" in roll) {
    const label = SAVE_TYPE_LABELS[String(options?.saveType ?? "")] ?? "豁免";
    const outcome = formatSaveOutcome(Boolean(roll.success), options?.onSaveSuccess);
    return `${label}豁免 d20${formatSigned(bonus)} vs DC${readNumber(roll.dc)} ${rollResult} ${outcome}`;
  }
  return null;
}

export function formatTopBarCheckSuffix(payload: Record<string, unknown>) {
  const saveOptions = {
    saveType: payload.saveType,
    onSaveSuccess: payload.onSaveSuccess,
  };
  const part =
    formatTopBarCheckRoll(payload.attackRoll, { isCrit: payload.isCrit }) ??
    formatTopBarCheckRoll(payload.saveRoll, saveOptions);
  return part ? ` ${part}` : "";
}

export function normalizeTopBarCheckText(text: string) {
  const saveMatch = text.match(
    /^(强韧|反射|意志|豁免)豁免(失败|成功（半伤）|成功（无伤）|成功)?\s*d20\s+(\d+)([-+]\d+)=(\d+)\s+vs\s+DC\s*(\d+)/,
  );
  if (saveMatch) {
    const [, label, outcome = "失败", roll, bonusText, total, dc] = saveMatch;
    return `${label}豁免 d20${bonusText} vs DC${dc} [${roll}]${bonusText} =${total} ${outcome}`;
  }

  const attackMatch = text.match(/^攻击检定\s+d20\s+(\d+)([-+]\d+)=(\d+)\s+vs\s+AC\s*(\d+)/);
  if (attackMatch) {
    const [, roll, bonusText, total, ac] = attackMatch;
    const rollNum = Number(roll);
    const totalNum = Number(total);
    const acNum = Number(ac);
    const hit = totalNum >= acNum;
    let outcome = hit ? "成功" : "失败";
    if (hit && (rollNum === 20 || text.includes("暴击"))) {
      outcome = "成功 暴击";
    }
    return `攻击检定 d20${bonusText} vs AC${ac} [${roll}]${bonusText} =${total} ${outcome}`;
  }

  return text;
}

export function splitRollBriefDisplay(text: string) {
  const bracketIdx = text.indexOf("[");
  if (bracketIdx >= 0) {
    return {
      prefix: text.slice(0, bracketIdx).trimEnd(),
      rollText: text.slice(bracketIdx).trimStart(),
    };
  }
  const equalsIdx = text.lastIndexOf("=");
  if (equalsIdx > 0) {
    return {
      prefix: text.slice(0, equalsIdx).trimEnd(),
      rollText: text.slice(equalsIdx).trimStart(),
    };
  }
  return {
    prefix: text,
    rollText: "",
  };
}

/** @deprecated Use splitRollBriefDisplay */
export const splitDamageRollDisplay = splitRollBriefDisplay;

export function formatRollSuffix(payload: Record<string, unknown>, includeDamage: boolean) {
  const saveOptions = {
    saveType: payload.saveType,
    onSaveSuccess: payload.onSaveSuccess,
  };
  const parts = [
    formatCheckRoll(payload.attackRoll) ?? formatCheckRoll(payload.saveRoll, saveOptions),
    includeDamage ? formatDamageRoll(payload.damageRoll) : null,
  ].filter((part): part is string => Boolean(part));
  return parts.length > 0 ? `（${parts.join("；")}）` : "";
}
