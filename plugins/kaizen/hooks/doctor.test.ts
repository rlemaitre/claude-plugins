import { expect, test } from 'claude-code/testing'
import { USAGE } from './doctor'

const MANIFEST = '{"name":"kaizen","version":"0.1.0"}'
const RUN = { origin: { kind: 'composer' }, presentation: { isFullscreen: false, columns: 120 } } as const
const GH_OK = { exitCode: 0, stdout: 'gh version 2.0.0', stderr: '', isStdoutTruncated: false, isStderrTruncated: false }

test('doctor reports a healthy install', async ($, on) => {
  on('fs.read', () => ({ value: MANIFEST }))
  on('fs.exists', () => ({ value: true }))
  on('process.run', () => ({ value: GH_OK }))
  const { text } = await $.command.run({ ...RUN, command: 'kaizen', args: 'doctor' })
  expect(text).toBe('kaizen 0.1.0\nrules: found\ngh: found')
})

test('doctor reports what is missing', async ($, on) => {
  on('fs.read', () => ({ value: MANIFEST }))
  on('fs.exists', () => ({ value: false }))
  on('process.run', () => {
    throw new Error('ENOENT')
  })
  const { text } = await $.command.run({ ...RUN, command: 'kaizen', args: 'doctor' })
  expect(text).toBe('kaizen 0.1.0\nrules: missing (rules/core.md)\ngh: missing')
})

test('doctor treats a failing gh as missing', async ($, on) => {
  on('fs.read', () => ({ value: MANIFEST }))
  on('fs.exists', () => ({ value: true }))
  on('process.run', () => ({ value: { ...GH_OK, exitCode: 1 } }))
  const { text } = await $.command.run({ ...RUN, command: 'kaizen', args: 'doctor' })
  expect(text?.split('\n').at(-1)).toBe('gh: missing')
})

test('kaizen with no argument shows the usage', async $ => {
  const { text } = await $.command.run({ ...RUN, command: 'kaizen', args: '' })
  expect(text).toBe(USAGE)
})

test('kaizen with an unknown argument shows the usage', async $ => {
  const { text } = await $.command.run({ ...RUN, command: 'kaizen', args: 'frobnicate' })
  expect(text).toBe(USAGE)
})
