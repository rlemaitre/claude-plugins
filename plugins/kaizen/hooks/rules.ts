import type { EngineInterface } from 'claude-code'

export const RULES_PATH = 'rules/core.md'

export async function readRules($: EngineInterface): Promise<string | undefined> {
  try {
    return await $.fs.read(`${$.plugin.root}/${RULES_PATH}`)
  } catch {
    return undefined
  }
}
