import type { EngineInterface } from 'claude-code'

import { readRules, RULES_PATH } from './rules'

export const USAGE = 'Usage: /kaizen doctor'

async function version($: EngineInterface): Promise<string> {
  const manifest = await $.fs.read(`${$.plugin.root}/.claude-plugin/plugin.json`)
  return JSON.parse(manifest).version
}

async function hasGh($: EngineInterface): Promise<boolean> {
  try {
    const { exitCode } = await $.process.run(['gh', '--version'], { timeoutMs: 5000 })
    return exitCode === 0
  } catch {
    return false
  }
}

export async function doctorReport($: EngineInterface): Promise<string> {
  const rules = (await readRules($)) !== undefined
  return [
    `kaizen ${await version($)}`,
    `rules: ${rules ? 'found' : `missing (${RULES_PATH})`}`,
    `gh: ${(await hasGh($)) ? 'found' : 'missing'}`,
  ].join('\n')
}
