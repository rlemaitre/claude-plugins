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
    return await $.fs.read(`${$.plugin.root}/${RULES_PATH}`)
  } catch {
    return undefined
  }
}
