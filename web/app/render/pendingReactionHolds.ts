export type ReactionCueKind = "counter" | "guard";

export type ReactionHoldIntent = {
  reactorId: string;
  sourceAttackerId: string;
  reactorTeam: string;
  cueKind: ReactionCueKind;
  queuedAt: number;
  until: number;
};

export type ReactionHoldBinding = {
  reactorId: string;
  sourceAttackerId: string;
  cueKind: ReactionCueKind;
  queuedAt: number;
  holdUntil: number;
};

export type ReactionHoldClash = {
  attackerId: string;
  targetIds: string[];
  startedAt: number;
  holdUntil?: number;
  reactionBindings?: ReactionHoldBinding[];
};

type ResolveTeam = (unitId: string) => string;

function getReactionPriority(cueKind: ReactionCueKind) {
  return cueKind === "counter" ? 0 : 1;
}

function recomputeClashHoldUntil(clash: ReactionHoldClash) {
  const bindings = clash.reactionBindings ?? [];
  let nextHoldUntil = 0;
  for (const binding of bindings) {
    nextHoldUntil = Math.max(nextHoldUntil, binding.holdUntil);
  }
  clash.holdUntil = nextHoldUntil > 0 ? nextHoldUntil : undefined;
}

function upsertReactionBinding(clash: ReactionHoldClash, intent: ReactionHoldIntent, holdUntil: number) {
  const bindings = clash.reactionBindings ?? [];
  const existing = bindings.find(
    (binding) =>
      binding.reactorId === intent.reactorId &&
      binding.sourceAttackerId === clash.attackerId &&
      binding.cueKind === intent.cueKind,
  );
  if (existing) {
    existing.holdUntil = Math.max(existing.holdUntil, holdUntil);
    existing.queuedAt = Math.min(existing.queuedAt, intent.queuedAt);
  } else {
    bindings.push({
      reactorId: intent.reactorId,
      sourceAttackerId: clash.attackerId,
      cueKind: intent.cueKind,
      queuedAt: intent.queuedAt,
      holdUntil,
    });
  }
  bindings.sort((left, right) => {
    const priorityDiff = getReactionPriority(left.cueKind) - getReactionPriority(right.cueKind);
    if (priorityDiff !== 0) {
      return priorityDiff;
    }
    return left.queuedAt - right.queuedAt;
  });
  clash.reactionBindings = bindings;
  recomputeClashHoldUntil(clash);
}

function matchesReactionHold(
  clash: ReactionHoldClash,
  intent: ReactionHoldIntent,
  resolveTeam: ResolveTeam,
) {
  if (clash.attackerId === intent.reactorId) {
    return false;
  }

  if (clash.targetIds.includes(intent.reactorId)) {
    if (intent.sourceAttackerId !== "" && clash.attackerId !== intent.sourceAttackerId) {
      return false;
    }
    return true;
  }

  if (!intent.reactorTeam) {
    return false;
  }

  if (intent.cueKind !== "guard" && intent.sourceAttackerId !== "") {
    return false;
  }

  if (intent.cueKind === "guard" && intent.sourceAttackerId !== "" && clash.attackerId !== intent.sourceAttackerId) {
    return false;
  }

  return clash.targetIds.some((targetId) => resolveTeam(targetId) === intent.reactorTeam);
}

export function createReactionHoldIntent(
  reactorId: string,
  sourceAttackerId: string,
  reactorTeam: string,
  cueKind: ReactionCueKind,
  now: number,
  matchWindowMs: number,
): ReactionHoldIntent {
  return {
    reactorId,
    sourceAttackerId,
    reactorTeam,
    cueKind,
    queuedAt: now,
    until: now + matchWindowMs,
  };
}

export function tryAttachReactionHold(
  clashes: ReactionHoldClash[],
  intent: ReactionHoldIntent,
  resolveTeam: ResolveTeam,
  now: number,
  matchWindowMs: number,
  queueHoldMs: number,
) {
  for (let index = clashes.length - 1; index >= 0; index -= 1) {
    const clash = clashes[index];
    if (now - clash.startedAt > matchWindowMs) {
      break;
    }
    if (!matchesReactionHold(clash, intent, resolveTeam)) {
      continue;
    }
    upsertReactionBinding(clash, intent, now + queueHoldMs);
    return true;
  }
  return false;
}

export function applyPendingReactionHoldsToClash(
  pending: ReactionHoldIntent[],
  clash: ReactionHoldClash,
  resolveTeam: ResolveTeam,
  now: number,
  queueHoldMs: number,
) {
  const remaining: ReactionHoldIntent[] = [];
  const candidates = [...pending].sort((left, right) => {
    const priorityDiff = getReactionPriority(left.cueKind) - getReactionPriority(right.cueKind);
    if (priorityDiff !== 0) {
      return priorityDiff;
    }
    return left.queuedAt - right.queuedAt;
  });

  for (const intent of candidates) {
    if (intent.until < now) {
      continue;
    }
    if (!matchesReactionHold(clash, intent, resolveTeam)) {
      remaining.push(intent);
      continue;
    }
    upsertReactionBinding(clash, intent, now + queueHoldMs);
  }

  return remaining;
}

export function prunePendingReactionHolds(pending: ReactionHoldIntent[], now: number) {
  return pending.filter((intent) => intent.until >= now);
}

export function extendReactionHoldForReactor(
  clashes: ReactionHoldClash[],
  reactorId: string,
  sourceAttackerId: string,
  holdUntil: number,
) {
  for (let index = clashes.length - 1; index >= 0; index -= 1) {
    const clash = clashes[index];
    const bindings = clash.reactionBindings ?? [];
    const binding = bindings.find((candidate) => {
      if (candidate.reactorId !== reactorId) {
        return false;
      }
      if (sourceAttackerId !== "" && candidate.sourceAttackerId !== sourceAttackerId) {
        return false;
      }
      return true;
    });
    if (!binding) {
      continue;
    }
    binding.holdUntil = Math.max(binding.holdUntil, holdUntil);
    recomputeClashHoldUntil(clash);
    return true;
  }
  return false;
}
