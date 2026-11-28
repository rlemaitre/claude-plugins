import type { Register } from 'claude-code'

import { doctorReport, USAGE } from './doctor'

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'kaizen', description: 'kaizen: doctor', argumentHint: '[doctor]' })
    return next(e)
  })

  on('command.run', { command: 'kaizen' }, async ($, e) => ({
    text: e.args.trim() === 'doctor' ? await doctorReport($) : USAGE,
  }))
}
