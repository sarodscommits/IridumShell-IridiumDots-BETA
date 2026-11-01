.pragma library
// Button colors per variant: [container, content, border | null]

function _filled(m3, tg, on)   { return tg && !on ? [m3.glassy(m3.surfaceContainerHighest, 0.7), m3.inkSurfaceVariant, null] : [m3.primary, m3.inkPrimary, null] }
function _tonal(m3, tg, on)    { return tg && on ? [m3.secondary, m3.inkSecondary, null] : [m3.glassy(m3.secondaryContainer, 0.75), m3.inkSecondaryContainer, null] }
function _outlined(m3, tg, on) { return tg && on ? [m3.inverseSurface, m3.inverseOnSurface, null] : [m3.alpha(m3.surface, 0), m3.inkSurfaceVariant, m3.outlineVariant] }
function _elevated(m3, tg, on) { return tg && on ? [m3.primary, m3.inkPrimary, null] : [m3.glassy(m3.surfaceContainerLow, 0.75), m3.primary, null] }
function _tertiary(m3, tg, on) { return tg && !on ? [m3.glassy(m3.tertiaryContainer, 0.75), m3.inkTertiaryContainer, null] : [m3.tertiary, m3.inkTertiary, null] }
function _standard(m3, tg, on, tint) {
    const ink = (tint && tint.a > 0) ? tint : (tg && on ? m3.primary : m3.inkSurfaceVariant)
    return [m3.alpha(m3.surface, 0), ink, null]
}

function colors(m3, variant, tg, on, tint, fallback) {
    switch (variant) {
    case "filled":   return _filled(m3, tg, on)
    case "tonal":    return _tonal(m3, tg, on)
    case "outlined": return _outlined(m3, tg, on)
    case "elevated": return _elevated(m3, tg, on)
    case "tertiary": return _tertiary(m3, tg, on)
    case "text":     return [m3.alpha(m3.surface, 0), m3.primary, null]
    case "error":    return [m3.errorContainer, m3.inkErrorContainer, null]
    case "standard": return _standard(m3, tg, on, tint)
    default:         return colors(m3, fallback || "filled", tg, on, tint, "filled")
    }
}
