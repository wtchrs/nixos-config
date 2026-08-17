// IntelliJ-like smooth caret for Ghostty
// Requires Ghostty 1.3+ cursor shader uniforms.
//
// Design:
// - Native cursor is hidden with `cursor-opacity = 0`.
// - This shader redraws it from iCurrentCursor/iPreviousCursor.
// - Movement uses an aggressive ease-out ("Snappy").
// - Blinking is a smooth periodic alpha transition.
// - Cursor geometry stays rectangular with sharp 90-degree corners.
// - Glyphs under a block cursor are redrawn above the cursor.
//
// Ghostty cursor rect convention:
//   rect.xy = (-X, +Y) corner (top-left in Shadertoy-style pixel space)
//   rect.zw = width, height

const float MOVE_DURATION_SEC = 0.115;
const float SNAPPY_POWER      = 5.5;

// Enable cursor blinking when true.
const bool ENABLE_BLINK       = true;

// Keep the caret fully visible after movement/typing before blinking starts.
const float BLINK_DELAY_SEC   = 0.45;

// IntelliJ's "Caret blinking (ms)" is commonly used as a half-cycle concept.
// 0.50 sec => roughly 500 ms visible/hidden cadence.
const float BLINK_HALF_SEC    = 0.60;

// 0 = pure sinusoidal breathing, higher = more distinct on/off plateaus.
// Keep below 0.5.
const float BLINK_SOFT_EDGE   = 0.18;

// Work around Ghostty's current/previous cursor ambiguity during large
// output/scroll jumps. Set very high (e.g. 1000.0) to animate all jumps.
const float MAX_ANIM_LINES    = 1000.0;

// Anti-alias width in output pixels.
const float AA_PX             = 1.0;

// Glyph detection is based on color distance from the estimated cell
// background. Increase these values if background noise is misdetected.
const float GLYPH_EDGE_LOW    = 0.035;
const float GLYPH_EDGE_HIGH   = 0.090;

float snappyEase(float t) {
    t = clamp(t, 0.0, 1.0);
    return 1.0 - pow(1.0 - t, SNAPPY_POWER);
}

float smoothBlink(float age) {
    // Keep the cursor permanently visible when blinking is disabled.
    if (!ENABLE_BLINK) return 1.0;

    if (age < BLINK_DELAY_SEC) return 1.0;

    float cycle = 2.0 * BLINK_HALF_SEC;
    float p = mod(age - BLINK_DELAY_SEC, cycle) / cycle;

    // 1 at p=0, 0 at p=0.5, 1 at p=1.
    float wave = 0.5 + 0.5 * cos(6.28318530718 * p);

    // Convert the cosine into a soft square wave:
    // stable bright/dark regions with smooth transitions.
    return smoothstep(BLINK_SOFT_EDGE, 1.0 - BLINK_SOFT_EDGE, wave);
}

float sdBox(vec2 p, vec2 center, vec2 size) {
    // Axis-aligned rectangle with true 90-degree corners.
    vec2 q = abs(p - center) - 0.5 * size;
    return max(q.x, q.y);
}

vec2 rectCenter(vec4 r) {
    // y decreases from the cursor's +Y/top edge by its height.
    return vec2(r.x + 0.5 * r.z, r.y - 0.5 * r.w);
}

bool validRect(vec4 r) {
    return r.z > 0.0 && r.w > 0.0;
}

vec3 sampleBase(vec2 p) {
    vec2 uv = clamp(p / iResolution.xy, vec2(0.0), vec2(1.0));
    return texture(iChannel0, uv).rgb;
}

vec3 estimateCellBackground(vec4 r) {
    vec2 center = rectCenter(r);

    // Glyphs normally occupy the center of a terminal cell, so sample
    // four points near the corners to estimate the underlying cell color.
    vec2 offset = vec2(0.42 * r.z, 0.42 * r.w);

    vec3 a = sampleBase(center + vec2(-offset.x,  offset.y));
    vec3 b = sampleBase(center + vec2( offset.x,  offset.y));
    vec3 c = sampleBase(center + vec2(-offset.x, -offset.y));
    vec3 d = sampleBase(center + vec2( offset.x, -offset.y));

    return 0.25 * (a + b + c + d);
}

float glyphMask(vec3 pixel, vec4 cursorRect) {
    vec3 background = estimateCellBackground(cursorRect);

    // Text pixels differ from the cell background. The two thresholds
    // preserve anti-aliased glyph edges instead of producing a hard mask.
    float delta = length(pixel - background);
    return smoothstep(GLYPH_EDGE_LOW, GLYPH_EDGE_HIGH, delta);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 base = texture(iChannel0, uv);

    vec4 cur = iCurrentCursor;
    vec4 prev = iPreviousCursor;

    if (!validRect(cur)) {
        fragColor = base;
        return;
    }

    if (!validRect(prev)) {
        prev = cur;
    }

    float age = max(0.0, iTime - iTimeCursorChange);

    // Ghostty currently exposes only current + previous cursor state.
    // During large output/scroll jumps, "previous" can be visually unrelated.
    // Snap those jumps instead of flying across the terminal.
    float lineH = max(cur.w, prev.w);
    float jumpLines = length(rectCenter(cur) - rectCenter(prev)) / max(lineH, 1.0);
    bool animateMove = jumpLines <= MAX_ANIM_LINES;

    float t = animateMove
        ? snappyEase(age / MOVE_DURATION_SEC)
        : 1.0;

    vec4 caret = mix(prev, cur, t);

    vec2 center = rectCenter(caret);
    vec2 size = max(caret.zw, vec2(1.0));

    // Keep block/bar/underline geometry rectangular.
    // Ghostty/app-provided cursor dimensions are preserved, so applications
    // such as Vim/Neovim can still switch the cursor to a bar in insert mode.
    float d = sdBox(fragCoord, center, size);
    float shapeAlpha = 1.0 - smoothstep(-AA_PX, AA_PX, d);

    // We intentionally disable Ghostty's own blink in config and implement
    // the fade here. iCursorVisible still lets applications hide the real
    // terminal cursor with DECTCEM.
    float visible = (iCursorVisible.x > 0.5 && iFocus > 0) ? 1.0 : 0.0;
    float alpha = shapeAlpha * smoothBlink(age) * visible;

    // iCursorColor is the unmodified cursor RGB, so it remains usable when
    // cursor-opacity=0 hides Ghostty's native cursor.
    vec4 composited = mix(base, vec4(iCursorColor, 1.0), alpha);

    // A block cursor normally covers the complete character cell. Since
    // iChannel0 contains the already-rendered terminal image rather than a
    // separate glyph mask, estimate the glyph from its contrast against the
    // current cell background and redraw it after the cursor.
    bool blockCursor =
        int(iCurrentCursorStyle.x + 0.5) == CURSORSTYLE_BLOCK;

    if (blockCursor && alpha > 0.0) {
        // Glyph reconstruction is only valid inside the current cursor cell.
        // Check the cell bounds first so the relatively expensive background
        // sampling is skipped for fragments that cannot contribute to the glyph.
        float inCurrentCell = step(
            sdBox(
                fragCoord,
                rectCenter(cur),
                max(cur.zw, vec2(1.0))
            ),
            0.0
        );

        if (inCurrentCell > 0.0) {
            float glyph = glyphMask(base.rgb, cur);

            // Use the animated cursor alpha as well, so the glyph appears above
            // only the portion of the cursor that currently overlaps this cell.
            float glyphAlpha = glyph * alpha;

            // iCursorText is Ghostty's configured text color under the cursor.
            // Drawing it last makes the glyph visually sit above the cursor.
            composited = mix(
                composited,
                vec4(iCursorText, 1.0),
                glyphAlpha
            );
        }
    }

    fragColor = composited;
}
