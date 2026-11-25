// IAMJARL design tokens v1.38.0 for Jetpack Compose. Generated from tokens.json by
// scripts/build.js: do not edit. Copy it from the release tag your app pins, as the
// README says under "Android (Jetpack Compose)"; DesignTokens.VERSION is the version.
// It needs androidx.compose.ui and androidx.compose.material3.
@file:Suppress("EnumEntryName", "unused")

package com.iamjarl.design

import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * The IAMJARL design tokens: the same groups as the Swift package, from the same
 * tokens.json. Colours that follow the system's light or dark setting are in
 * [Palette]; their two values are in [ColorToken.Light] and [ColorToken.Dark].
 *
 *     Text("Start", color = DesignTokens.Palette.Text.primary,
 *          style = DesignTokens.Typography.Style.lg.textStyle)
 */
object DesignTokens {
    /** The tokens.json version this file was generated from. */
    const val VERSION: String = "1.38.0"

    object Spacing {
        val xs: Dp = 4.dp
        val sm: Dp = 8.dp
        val md: Dp = 12.dp
        val lg: Dp = 16.dp
        val xl: Dp = 20.dp
        val xxl: Dp = 24.dp
        val xxxl: Dp = 32.dp
    }

    object Radius {
        val sm: Dp = 8.dp
        val md: Dp = 12.dp
        val lg: Dp = 16.dp
    }

    object Typography {
        /** Sizes in sp, so the system font size scales them. */
        object Size {
            val xs: TextUnit = 12.sp
            val sm: TextUnit = 14.sp
            val base: TextUnit = 16.sp
            val lg: TextUnit = 18.sp
            val xl: TextUnit = 24.sp
            val xxl: TextUnit = 36.sp
        }

        object LineHeight {
            val xs: TextUnit = 16.sp
            val sm: TextUnit = 20.sp
            val base: TextUnit = 24.sp
            val lg: TextUnit = 28.sp
            val xl: TextUnit = 32.sp
            val xxl: TextUnit = 44.sp
        }

        object Weight {
            val regular: FontWeight = FontWeight(400)
            val semibold: FontWeight = FontWeight(600)
            val bold: FontWeight = FontWeight(700)
        }

        /**
         * The text scale, as styles in sp that follow the system font size. [material3]
         * puts each in the Material 3 slot nearest it, so MaterialTheme carries the scale.
         */
        enum class Style(val size: TextUnit, val lineHeight: TextUnit, val material3Slot: String) {
            xs(Size.xs, LineHeight.xs, "bodySmall"),
            sm(Size.sm, LineHeight.sm, "bodyMedium"),
            base(Size.base, LineHeight.base, "bodyLarge"),
            lg(Size.lg, LineHeight.lg, "titleMedium"),
            xl(Size.xl, LineHeight.xl, "headlineSmall"),
            xxl(Size.xxl, LineHeight.xxl, "displaySmall");

            val textStyle: TextStyle get() = TextStyle(fontSize = size, lineHeight = lineHeight)
        }

        /**
         * Material 3's type scale with the token sizes in their slots: xs bodySmall, sm bodyMedium, base bodyLarge, lg titleMedium, xl headlineSmall, xxl displaySmall.
         * Every other property of a slot is Material 3's own. Pass it to MaterialTheme.
         */
        fun material3(
            base: androidx.compose.material3.Typography = androidx.compose.material3.Typography(),
        ): androidx.compose.material3.Typography = base.copy(
            bodySmall = base.bodySmall.copy(fontSize = Size.xs, lineHeight = LineHeight.xs),
            bodyMedium = base.bodyMedium.copy(fontSize = Size.sm, lineHeight = LineHeight.sm),
            bodyLarge = base.bodyLarge.copy(fontSize = Size.base, lineHeight = LineHeight.base),
            titleMedium = base.titleMedium.copy(fontSize = Size.lg, lineHeight = LineHeight.lg),
            headlineSmall = base.headlineSmall.copy(fontSize = Size.xl, lineHeight = LineHeight.xl),
            displaySmall = base.displaySmall.copy(fontSize = Size.xxl, lineHeight = LineHeight.xxl),
        )

        /** Numbers that are the interface: timers, counters, readouts. Set one with [numeral]. */
        enum class Numeral(val size: TextUnit) {
            sm(32.sp),
            md(56.sp),
            lg(80.sp);
        }

        /** How far a numeral may grow with the system font size, as a multiple of its size. */
        const val numeralMaxScale: Float = 1.5f

        /**
         * A numeral's style: tabular digits, so it does not shift sideways as the digits
         * change, growing with the system font size up to [numeralMaxScale].
         */
        @Composable
        fun numeral(numeral: Numeral, weight: FontWeight = FontWeight.Bold): TextStyle {
            val fontScale = LocalDensity.current.fontScale
            val scale = minOf(fontScale, numeralMaxScale)
            return TextStyle(
                fontSize = (numeral.size.value * scale / fontScale).sp,
                fontWeight = weight,
                fontFeatureSettings = "tnum",
            )
        }
    }

    object Shadow {
        data class Value(val x: Dp, val y: Dp, val blur: Dp, val opacity: Float)

        val sm: Value = Value(x = 0.dp, y = 1.dp, blur = 2.dp, opacity = 0.05f)
        val md: Value = Value(x = 0.dp, y = 4.dp, blur = 8.dp, opacity = 0.08f)
        val lg: Value = Value(x = 0.dp, y = 8.dp, blur = 24.dp, opacity = 0.12f)
    }

    object Motion {
        /** Milliseconds, as tween() and the animation specs take them. */
        object Duration {
            const val fast: Int = 150
            const val normal: Int = 250
            const val slow: Int = 400
        }

        object Easing {
            val standard: CubicBezierEasing = CubicBezierEasing(0.4f, 0f, 0.2f, 1f)
            val emphasized: CubicBezierEasing = CubicBezierEasing(0.2f, 0f, 0f, 1f)
        }
    }

    object Container {
        val sm: Dp = 680.dp
        val md: Dp = 900.dp
        val lg: Dp = 1080.dp
        val xl: Dp = 1400.dp
    }

    /** Widths in dp, for adaptive layouts. */
    object Breakpoint {
        val popup: Dp = 320.dp
        val sm: Dp = 640.dp
        val md: Dp = 768.dp
        val lg: Dp = 1024.dp
        val xl: Dp = 1280.dp
        val xxl: Dp = 1536.dp
    }

    object Focus {
        val width: Dp = 2.dp
        val offset: Dp = 2.dp
    }

    /** For Modifier.zIndex(). */
    object ZIndex {
        const val base: Float = 0f
        const val dropdown: Float = 1000f
        const val sticky: Float = 1100f
        const val overlay: Float = 1200f
        const val modal: Float = 1300f
        const val popover: Float = 1400f
        const val toast: Float = 1500f
        const val tooltip: Float = 1600f
    }

    object Opacity {
        const val disabled: Float = 0.4f
        const val muted: Float = 0.65f
    }

    object ColorToken {
        val black: Color = Color(0xFF000000)
        val white: Color = Color(0xFFFFFFFF)

        /** The shared state fills. Not mode-dependent; pair each with its on- colour. */
        object State {
            val success: Color = Color(0xFF4CAF50)
            val onSuccess: Color = Color(0xFF000000)
            val warning: Color = Color(0xFFFF6B35)
            val onWarning: Color = Color(0xFF000000)
            val error: Color = Color(0xFFD70015)
            val onError: Color = Color(0xFFFFFFFF)
        }

        object Light {
            val primary: Color = Color(0xFFA435D2)
            val onPrimary: Color = Color(0xFFFFFFFF)
            val primaryHover: Color = Color(0xFF8E2BB8)
            val primaryPressed: Color = Color(0xFF7A2499)
            val primarySubtle: Color = Color(0x1FA435D2) // rgba(164, 53, 210, 0.12)

            object Text {
                val primary: Color = Color(0xFF000000)
                val secondary: Color = Color(0xB3000000) // rgba(0, 0, 0, 0.70)
                val tertiary: Color = Color(0x8C000000) // rgba(0, 0, 0, 0.55)
                val disabled: Color = Color(0x59000000) // rgba(0, 0, 0, 0.35)
                val inverse: Color = Color(0xFFFFFFFF)
            }

            object Background {
                val app: Color = Color(0xFFFFFFFF)
                val muted: Color = Color(0x0A000000) // rgba(0, 0, 0, 0.04)
                val card: Color = Color(0x0A000000) // rgba(0, 0, 0, 0.04)
                val disabled: Color = Color(0x0F000000) // rgba(0, 0, 0, 0.06)
            }

            object Surface {
                val default: Color = Color(0xFFFFFFFF)
                val raised: Color = Color(0x05000000) // rgba(0, 0, 0, 0.02)
            }

            object Border {
                val subtle: Color = Color(0x1A000000) // rgba(0, 0, 0, 0.10)
                val default: Color = Color(0x29000000) // rgba(0, 0, 0, 0.16)
            }

            object State {
                val success: Color = Color(0xFF2E7D32)
                val warning: Color = Color(0xFFC2410C)
                val error: Color = Color(0xFFD70015)
            }
        }

        object Dark {
            val primary: Color = Color(0xFFD0FF00)
            val onPrimary: Color = Color(0xFF000000)
            val primaryHover: Color = Color(0xFFB8E000)
            val primaryPressed: Color = Color(0xFFA0C400)
            val primarySubtle: Color = Color(0x26D0FF00) // rgba(208, 255, 0, 0.15)

            object Text {
                val primary: Color = Color(0xFFFFFFFF)
                val secondary: Color = Color(0xBFFFFFFF) // rgba(255, 255, 255, 0.75)
                val tertiary: Color = Color(0x99FFFFFF) // rgba(255, 255, 255, 0.60)
                val disabled: Color = Color(0x59FFFFFF) // rgba(255, 255, 255, 0.35)
                val inverse: Color = Color(0xFF000000)
            }

            object Background {
                val app: Color = Color(0xFF000000)
                val muted: Color = Color(0x0DFFFFFF) // rgba(255, 255, 255, 0.05)
                val card: Color = Color(0x0DFFFFFF) // rgba(255, 255, 255, 0.05)
                val disabled: Color = Color(0x12FFFFFF) // rgba(255, 255, 255, 0.07)
            }

            object Surface {
                val default: Color = Color(0xFF000000)
                val raised: Color = Color(0x08FFFFFF) // rgba(255, 255, 255, 0.03)
            }

            object Border {
                val subtle: Color = Color(0x1FFFFFFF) // rgba(255, 255, 255, 0.12)
                val default: Color = Color(0x2EFFFFFF) // rgba(255, 255, 255, 0.18)
            }

            object State {
                val success: Color = Color(0xFF4CAF50)
                val warning: Color = Color(0xFFFF6B35)
                val error: Color = Color(0xFFFF453A)
            }
        }
    }

    /** Light or dark by a flag: the choice [adaptive] makes from the system setting. */
    fun <T> pick(light: T, dark: T, isDark: Boolean): T = if (isDark) dark else light

    /** A colour that follows the system's light or dark setting, as DesignTokens.adaptive does in SwiftUI. */
    @Composable
    fun adaptive(light: Color, dark: Color): Color = pick(light, dark, isSystemInDarkTheme())

    /**
     * Every mode-aware colour, following the system's light or dark setting. The
     * shared state fills are not mode-dependent and stay in [ColorToken.State].
     */
    object Palette {
        val primary: Color @Composable get() = adaptive(ColorToken.Light.primary, ColorToken.Dark.primary)
        val onPrimary: Color @Composable get() = adaptive(ColorToken.Light.onPrimary, ColorToken.Dark.onPrimary)
        val primaryHover: Color @Composable get() = adaptive(ColorToken.Light.primaryHover, ColorToken.Dark.primaryHover)
        val primaryPressed: Color @Composable get() = adaptive(ColorToken.Light.primaryPressed, ColorToken.Dark.primaryPressed)
        val primarySubtle: Color @Composable get() = adaptive(ColorToken.Light.primarySubtle, ColorToken.Dark.primarySubtle)

        object Text {
            val primary: Color @Composable get() = adaptive(ColorToken.Light.Text.primary, ColorToken.Dark.Text.primary)
            val secondary: Color @Composable get() = adaptive(ColorToken.Light.Text.secondary, ColorToken.Dark.Text.secondary)
            val tertiary: Color @Composable get() = adaptive(ColorToken.Light.Text.tertiary, ColorToken.Dark.Text.tertiary)
            val disabled: Color @Composable get() = adaptive(ColorToken.Light.Text.disabled, ColorToken.Dark.Text.disabled)
            val inverse: Color @Composable get() = adaptive(ColorToken.Light.Text.inverse, ColorToken.Dark.Text.inverse)
        }

        object Background {
            val app: Color @Composable get() = adaptive(ColorToken.Light.Background.app, ColorToken.Dark.Background.app)
            val muted: Color @Composable get() = adaptive(ColorToken.Light.Background.muted, ColorToken.Dark.Background.muted)
            val card: Color @Composable get() = adaptive(ColorToken.Light.Background.card, ColorToken.Dark.Background.card)
            val disabled: Color @Composable get() = adaptive(ColorToken.Light.Background.disabled, ColorToken.Dark.Background.disabled)
        }

        object Surface {
            val default: Color @Composable get() = adaptive(ColorToken.Light.Surface.default, ColorToken.Dark.Surface.default)
            val raised: Color @Composable get() = adaptive(ColorToken.Light.Surface.raised, ColorToken.Dark.Surface.raised)
        }

        object Border {
            val subtle: Color @Composable get() = adaptive(ColorToken.Light.Border.subtle, ColorToken.Dark.Border.subtle)
            val default: Color @Composable get() = adaptive(ColorToken.Light.Border.default, ColorToken.Dark.Border.default)
        }

        object State {
            val success: Color @Composable get() = adaptive(ColorToken.Light.State.success, ColorToken.Dark.State.success)
            val warning: Color @Composable get() = adaptive(ColorToken.Light.State.warning, ColorToken.Dark.State.warning)
            val error: Color @Composable get() = adaptive(ColorToken.Light.State.error, ColorToken.Dark.State.error)
        }
    }
}
