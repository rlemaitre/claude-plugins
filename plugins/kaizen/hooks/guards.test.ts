import { expect, test } from 'claude-code/testing'
import { guardVerdict } from './guards'

const CASES: [string, 'deny' | 'ask' | undefined][] = [
  ['git add -A', 'deny'],
  ['git add --all', 'deny'],
  ['git add .', 'deny'],
  ['git -C ../repo add -A', 'deny'],
  ['git status && git add -A', 'deny'],
  ['git commit -am "msg"', 'deny'],
  ['git commit -a -m msg', 'deny'],
  ['git push --force', 'deny'],
  ['cd x; git push -f origin main', 'deny'],
  ['git push origin +main', 'deny'],
  ['git push --force-with-lease', 'deny'],
  ['git push', 'ask'],
  ['git push -u origin feature', 'ask'],
  ['git add src/a.ts README.md', undefined],
  ['git commit -m "add -A flag"', undefined],
  ['echo git push', undefined],
  ['git log --all', undefined],
  ['(cd ../repo && git push)', 'ask'],
  ['(git add -A)', 'deny'],
  ['env git push', 'ask'],
  ['GIT_DIR=x git push --force', 'deny'],
  ['/usr/bin/git add -A', 'deny'],
  ['sleep 1 & git push', 'ask'],
  ['echo $(git push)', 'ask'],
  ['echo `git push -f`', 'deny'],
  ['git add -u', 'deny'],
  ['git add --update', 'deny'],
  ['git add -Av', 'deny'],
  ['git add -p src/a.ts', undefined],
]

for (const [command, decision] of CASES) {
  test(`guardVerdict: ${command} → ${decision ?? 'nothing'}`, () => {
    expect(guardVerdict(command)?.decision).toBe(decision)
  })
}

test('the stage-all reason names the rule', () => {
  expect(guardVerdict('git add -A')?.reason).toBe('kaizen: stage files by path, never all at once.')
})

test('the force-push reason names the rule', () => {
  expect(guardVerdict('git push --force')?.reason).toBe('kaizen: never force-push; Raph pushes those himself.')
})

test('the push reason names the rule', () => {
  expect(guardVerdict('git push')?.reason).toBe("kaizen: push only on Raph's OK.")
})

test('the tool.check hook refuses git add -A', async ($, on) => {
  on('tool.check', () => ({ decision: 'allow' }))
  const result = await $.tool.check({ tool: 'Bash', input: { command: 'git add -A' } })
  expect(result.decision).toBe('deny')
  expect(result.reason).toBe('kaizen: stage files by path, never all at once.')
})

test('the tool.check hook asks before git push', async ($, on) => {
  on('tool.check', () => ({ decision: 'allow' }))
  const result = await $.tool.check({ tool: 'Bash', input: { command: 'git push' } })
  expect(result.decision).toBe('ask')
})

test('the tool.check hook leaves other commands to the engine', async ($, on) => {
  on('tool.check', () => ({ decision: 'allow' }))
  const result = await $.tool.check({ tool: 'Bash', input: { command: 'ls' } })
  expect(result.decision).toBe('allow')
})

test('the tool.check hook passes a malformed input to the engine', async ($, on) => {
  on('tool.check', () => ({ decision: 'allow' }))
  const result = await $.tool.check({ tool: 'Bash', input: 42 })
  expect(result.decision).toBe('allow')
})

test('an ask never hides a deny from beneath', async ($, on) => {
  on('tool.check', () => ({ decision: 'deny', reason: 'engine says no' }))
  const result = await $.tool.check({ tool: 'Bash', input: { command: 'git push' } })
  expect(result.decision).toBe('deny')
  expect(result.reason).toBe('engine says no')
})
