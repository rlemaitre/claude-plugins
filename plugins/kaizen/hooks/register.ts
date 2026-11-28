import type { Register } from 'claude-code'

import { doctorReport, USAGE } from './doctor'
import { readRules, withRules } from './rules'

export const register: Register = on => {
  on('prompt.context', async ($, e, next) => {
    const result = await next(e)
    return { ...result, blocks: withRules(result.blocks, await readRules($)) }
  })

  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'kaizen', description: 'kaizen: doctor', argumentHint: '[doctor]' })
    return next(e)
  })

  on('command.run', { command: 'kaizen' }, async ($, e) => ({
    text: e.args.trim() === 'doctor' ? await doctorReport($) : USAGE,
  }))
}
