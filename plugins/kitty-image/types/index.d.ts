export type Shown = { id: string; png: string; columns: number; rows: number; alt: string }

declare module 'claude-code' {
  interface PluginState {
    'kitty-image': { shown: Shaped<Shown[]> }
  }
}
