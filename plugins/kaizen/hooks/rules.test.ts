import { expect, test } from 'claude-code/testing'
import { withRules } from './rules'

test('adds the kaizen block after the engine blocks', () => {
  const blocks = withRules([{ name: 'currentDate', text: '2026-11-28' }], 'RULES')
  expect(blocks.map(b => b.name)).toEqual(['currentDate', 'kaizen'])
  expect(blocks[1].text).toBe('RULES')
})

test('adds the block when the context is empty', () => {
  expect(withRules([], 'RULES')).toEqual([{ name: 'kaizen', text: 'RULES' }])
})

test('replaces an earlier kaizen block instead of adding a second', () => {
  const blocks = withRules([{ name: 'kaizen', text: 'OLD' }], 'NEW')
  expect(blocks).toEqual([{ name: 'kaizen', text: 'NEW' }])
})

test('leaves the blocks unchanged when the rules could not be read', () => {
  const engine = [{ name: 'currentDate', text: '2026-11-28' }]
  expect(withRules(engine, undefined)).toEqual(engine)
})

test('the prompt.context hook adds the rules file', async ($, on) => {
  on('fs.read', () => ({ value: 'RULES' }))
  on('prompt.context', (_, e) => ({ blocks: e.blocks }))
  const result = await $.prompt.context({ blocks: [], instructionFiles: [] })
  expect(result.blocks).toEqual([{ name: 'kaizen', text: 'RULES' }])
})

test('the prompt.context hook passes through when the rules file is missing', async ($, on) => {
  on('fs.read', () => {
    throw new Error('ENOENT')
  })
  on('prompt.context', (_, e) => ({ blocks: e.blocks }))
  const result = await $.prompt.context({ blocks: [], instructionFiles: [] })
  expect(result.blocks).toEqual([])
})
