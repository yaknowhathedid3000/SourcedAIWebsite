# Yogi brand files

Exported from the mascot in `web/components/Mascot.tsx` and
`ios/Yogi/Yogi/DesignSystem/Mascot.swift`, so these stay in step with the app.

| File | Use |
|---|---|
| `yogi-mark.svg` | The mark alone, transparent. Scales to anything — prefer this. |
| `yogi-mark-white.svg` | Mark on a white square with padding. |
| `yogi-mark-white-512/1024/2048.png` | Raster, white background. |
| `yogi-mark-transparent-1024.png` | Raster, transparent. |
| `yogi-lockup-white-1600/3200.png` | Mark + wordmark, horizontal, on white. |

The wordmark is EB Garamond 600 at -0.02em tracking. The lockup only exists as
PNG because an SVG with live text needs the font installed on the viewer's
machine; regenerate it from the site if the type changes.

Ink is `#1C1C1E`.
