export type Verdict = { decision: 'deny' | 'ask'; reason: string }

const STAGE_ALL: Verdict = { decision: 'deny', reason: 'kaizen: stage files by path, never all at once.' }
const FORCE_PUSH: Verdict = { decision: 'deny', reason: 'kaizen: never force-push; Raph pushes those himself.' }
const PUSH: Verdict = { decision: 'ask', reason: "kaizen: push only on Raph's OK." }

// git's own options that take the next word as their value.
const OPTIONS_WITH_VALUE = new Set(['-C', '-c'])

function gitCall(part: string): { sub: string; args: string[] } | undefined {
  const words = part.trim().split(/\s+/)
  if (words[0] !== 'git') return undefined
  let i = 1
  while (i < words.length && words[i]!.startsWith('-')) i += OPTIONS_WITH_VALUE.has(words[i]!) ? 2 : 1
  const sub = words[i]
  return sub === undefined ? undefined : { sub, args: words.slice(i + 1) }
}

function verdictFor({ sub, args }: { sub: string; args: string[] }): Verdict | undefined {
  if (sub === 'add' && args.some(a => a === '-A' || a === '--all' || a === '.')) return STAGE_ALL
  if (sub === 'commit' && args.some(a => a === '--all' || /^-[a-zA-Z]*a[a-zA-Z]*$/.test(a))) return STAGE_ALL
  if (sub !== 'push') return undefined
  const forced = args.some(a => a === '-f' || a.startsWith('--force') || a.startsWith('+'))
  return forced ? FORCE_PUSH : PUSH
}

export function guardVerdict(command: string): Verdict | undefined {
  // Quoted text (a commit message, an echo) is not a command: blank it before splitting.
  const unquoted = command.replace(/"[^"]*"|'[^']*'/g, 'Q')
  const verdicts = unquoted
    .split(/&&|\|\||;|\||\n/)
    .map(gitCall)
    .flatMap(call => (call === undefined ? [] : [verdictFor(call)]))
  return verdicts.find(v => v?.decision === 'deny') ?? verdicts.find(v => v !== undefined)
}
