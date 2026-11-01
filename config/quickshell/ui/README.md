# ui/

Generic M3 Expressive components. `shell.qml` imports them with `import "ui"`.

Components read `m3`, `m3shp`, `pal` and `globalState` from the instantiating context (`shell.qml`).

Shared pieces:
- `M3ColorAnim`, `M3NumberAnim`, `M3SpringAnim`: theme animations
- `Spring`: spring-driven value
- `StateLayer`: hover/press tint
- `ButtonColors.js`: button colors per variant
- `ShapeSequencer`: shape cycling with morph + spin
- `ESelectControl`: base for ECheck / ERadio
