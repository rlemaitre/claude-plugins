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

  on('tool.check', { tool: 'Bash' }, async ($, e, next) => {
    const command = (e.input as { command?: unknown } | undefined)?.command
    const verdict = typeof command === 'string' ? guardVerdict(command) : undefined
    if (verdict?.decision === 'deny') return verdict
    const beneath = await next(e)
    // An ask must never hide a deny from another guard, a rule or the classifier.
    return verdict === undefined || beneath.decision === 'deny' ? beneath : verdict
  })
}
