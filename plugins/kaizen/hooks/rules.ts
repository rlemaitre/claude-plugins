import type { EngineInterface, PromptContextBlock } from 'claude-code'

export const RULES_PATH = 'rules/core.md'

const BLOCK = 'kaizen'

export function withRules(
  blocks: readonly PromptContextBlock[],
  rules: string | undefined,
): PromptContextBlock[] {
  if (rules === undefined) return [...blocks]
  return [...blocks.filter(b => b.name !== BLOCK), { name: BLOCK, text: rules }]
}

export async function readRules($: EngineInterface): Promise<string | undefined> {
  try {
    const text = await $.fs.read(`${$.plugin.root}/${RULES_PATH}`)
    return typeof text === 'string' ? text : undefined
  } catch {
    return undefined
  }
}
