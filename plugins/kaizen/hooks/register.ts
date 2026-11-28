import type { Register } from 'claude-code'

import { doctorReport, USAGE } from './doctor'
import { guardVerdict } from './guards'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'kaizen', description: 'kaizen: doctor', argumentHint: '[doctor]' })
    return next(e)
  })

  on('command.run', { command: 'kaizen' }, async ($, e) => ({
    text: e.args.trim() === 'doctor' ? await doctorReport($) : USAGE,
  }))

  on('tool.check', { tool: 'Bash' }, ($, e, next) => {
    const command = (e.input as { command?: unknown } | undefined)?.command
    const verdict = typeof command === 'string' ? guardVerdict(command) : undefined
    return verdict ?? next(e)
  }).catch(($, e, next) => next(e))
}
