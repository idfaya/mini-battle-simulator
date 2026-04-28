const fs = require("fs");
const path = require("path");

const projectileRe = /projectile|fire|ball|ice|arrow|bolt|orb|arc|lightning|missile|shard/i;
const isMeleeClass = (c) => c >= 1 && c <= 5;

function scanLua(filePath) {
  const txt = fs.readFileSync(filePath, "utf8");
  const ops = [];
  const effects = [];
  for (const m of txt.matchAll(/\bop\s*=\s*["'](\w+)["']/g)) ops.push(m[1]);
  for (const m of txt.matchAll(/\beffect\s*=\s*["']([^"']+)["']/g)) effects.push(m[1]);
  return { ops, effects };
}

function uniq(arr) {
  return [...new Set(arr)];
}

function main() {
  const skills = JSON.parse(fs.readFileSync(path.join("config", "res_skill.json"), "utf8"));
  const rows = [];

  for (const s of skills) {
    const skillId = Number(s.ID);
    // Skill ids follow 8000CXXX where C is 1..9 (class/role id).
    const classId = Math.floor((skillId % 100000) / 1000);
    const type = Number(s.Type ?? 0);
    const name = String(s.Name ?? "");
    const luaPath = path.join("config", "skill", `skill_${skillId}.lua`);
    const exists = fs.existsSync(luaPath);

    let ops = [];
    let effects = [];
    if (exists) {
      ({ ops, effects } = scanLua(luaPath));
    }

    const hasProjectile = ops.includes("projectile");
    const hasDamage = ops.includes("damage") || ops.includes("chain_damage");
    const hasHeal = ops.includes("heal");
    const effectKeyword = effects.some((e) => projectileRe.test(e));

    let predicted = "";
    if (!exists) {
      predicted = type === 4 ? "PASSIVE(no lua timeline)" : "MISSING_LUA";
    } else if (hasProjectile) {
      predicted = "PROJECTILE_FRAME";
    } else if (hasDamage && isMeleeClass(classId)) {
      predicted = "MELEE_CLASH_ONLY";
    } else if (hasDamage && !isMeleeClass(classId)) {
      predicted = effectKeyword
        ? "RANGED_FALLBACK_PROJECTILE(style from effect/class)"
        : "RANGED_FALLBACK_PROJECTILE(default style risk)";
    } else {
      predicted = hasHeal ? "HEAL_ONLY(no projectile)" : "EFFECT_ONLY(no projectile)";
    }

    const note = [];
    if (exists && !hasProjectile && hasDamage && !isMeleeClass(classId) && !effectKeyword && classId === 7) {
      note.push("fire class but effect name lacks fire keywords -> default orb");
    }
    if (exists && !hasProjectile && !hasDamage && !hasHeal) {
      note.push("no damage/heal ops detected -> likely handler-driven");
    }

    rows.push({
      classId,
      skillId,
      type,
      name,
      predicted,
      note: note.join("; "),
      luaPath,
      ops: uniq(ops),
      effects: uniq(effects).slice(0, 6),
    });
  }

  rows.sort((a, b) => a.classId - b.classId || a.skillId - b.skillId);
  const groups = {};
  for (const r of rows) (groups[r.predicted] ||= []).push(r);

  const byType = Object.fromEntries(Object.entries(groups).map(([k, v]) => [k, v.length]));
  console.log(JSON.stringify({ total: rows.length, byType, rows }, null, 2));
}

main();
