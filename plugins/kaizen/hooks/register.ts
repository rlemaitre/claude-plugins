import type { Register } from 'claude-code'

import { readRules, withRules } from './rules'

export const register: Register = on => {
  on('prompt.context', async ($, e, next) => {
    const result = await next(e)
    return { ...result, blocks: withRules(result.blocks, await readRules($)) }
  }).catch(($, e, next) => next(e))
}
