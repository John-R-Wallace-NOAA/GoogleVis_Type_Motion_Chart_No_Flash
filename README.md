# MotionChart — Flash-Free Animated Motion Charts from R
Click on the image for an interactive demo. The demo opens in the current tab, so click the back arrow to go back to GitHub. <br>
(The demo works well, if it appears not to be working correctly, try a reload.)
[![ ](https://github.com/John-R-Wallace-NOAA/GoogleVis_Type_Motion_Chart_No_Flash/blob/main/Images/Gapminder_LifeExp_vs_Fertility.gif)](https://john-r-wallace-noaa.github.io)
<br>
<br>
[One more demo for Han Rosling's life expectancy by fertility for USA and Vietnam only](https://john-r-wallace-noaa.github.io/GoogleVis_Type_Motion_Chart_No_Flash/Motion_Chart_Fertility_US_Vietnam.github.io/Fert_US_Viet.htm)
<br>
<br>
<br>
A drop-in spiritual successor to `googleVis::gvisMotionChart` built on
[echarts4r](https://echarts4r.john-coene.com/) and Apache ECharts.  No Flash,
no browser plugin, no data uploaded anywhere.  All animation runs client-side
in the browser via a `requestAnimationFrame` loop; data stays local. 
<br>
<br>
Created by brainstorming sessions (8+ hours) with ChatGPT, 
and having a failed start before deciding the best path forward was to use echarts4r. The heavy lift coding was done by Claude, but I did have
some good coding inputs. However, I mostly contributed design ideas and what features to add. Claude did lead me astray by finding and quickly
using an R package that had Gapminder data without fertility information and with data only every 5 years. Without too much effort I found the DSLabs
R package which had more complete Gapminder data.

A strange new world, you direct the process, but sometimes you are just the monkey running code for AI and telling it what you see. If you need something customized, 
one approach is to just fork the repo, upload the necessary code file(s) and tell Claude or another AI what you need.

---

## Background

Hans Rosling's [animated bubble charts](https://www.youtube.com/watch?v=hVimVzgtD6w) — popularized by Gapminder and the BBC's
*Joy of Stats* — were originally powered by Google's Motion Chart, which
required Adobe Flash.  Flash reached end-of-life in December 2020 and is now
blocked by every major browser.  The `googleVis` package still carries
`gvisMotionChart` but its own documentation warns that Flash charts are no
longer supported.

No general-purpose, Flash-free, R-callable replacement existed on CRAN or
GitHub as of early 2026.  This package fills that gap.

---

## Features

- **Smooth animation** — client-side linear interpolation between real data
  time steps at ~60 fps; no pre-baking of frame data in R
- **Fading trails** — polyline + ghost bubbles showing each entity's recent
  path, matching the original Gapminder look
- **Play / Pause / Scrub** — control bar with slider and looping playback
  (2-second pause at end before restart)
- **Hover highlighting** — hover a bubble to isolate its group (`"group"` mode,
  default) or just that entity (`"entity"` mode); other bubbles and trails hide
- **Click locking** — click a bubble to pin the highlight; click again or click
  empty space to release
- **Pinned tooltip** — info box stays with the selected entity without chasing
  it; optionally follows the bubble smoothly with `tooltip_follow = TRUE`
- **Legend filtering** — click legend items to show/hide groups; trails follow
  automatically
- **Live label sizing** — A- / A+ buttons in the control bar adjust label font
  size without re-running R
- **Trails toggle** — Trails ON/OFF button in the control bar
- **Fixed axes** — global min/max computed across all time steps so axes never
  jump during animation
- **Log scale support** — `x_log` and `y_log` arguments
- **Title-cased default labels** — column names auto-formatted (e.g.
  `gdpPercap` → `GdpPercap`); override with `x_label`, `y_label`
- **Theme support** — any echarts4r theme via the `theme` argument
- **htmlwidget output** — works in RStudio Viewer, Shiny, R Markdown, Quarto

---

## Installation

```r
# Install remotes if needed
if (!any(installed.packages()[, 1] %in% "remotes"))
  install.packages("remotes")

remotes::install_github("John-R-Wallace-NOAA/GoogleVis_Type_Motion_Chart_No_Flash")
#
```

---

## Quick Start

```r
library(MotionChart)

gap_dslabs <- load_gapminder_dslabs()

motionChart(gap_dslabs,
            id    = "country",
            time  = "year",
            x     = "gdpPercap",
            y     = "life_expectancy",
            size  = "population",
            color = "continent",
            title = "Gapminder — Health & Wealth of Nations")

saveHtmlFolder()
openwd()  # To open the copied motion chart go to the newly created HTML folder and doulble-click on 'index.html'
```

---

## Full Argument Reference

```r
motionChart(gap_dslabs,
            id             = "country",
            time           = "year",
            x              = "gdpPercap",
            y              = "life_expectancy",
            size           = "population",    # NULL = uniform bubble size
            color          = "continent",     # NULL = single colour
            x_log          = TRUE,            # log scale on x axis
            y_log          = FALSE,           # log scale on y axis
            x_label        = "GDP per Capita (USD)",  # NULL = auto title-case
            y_label        = "Life Expectancy",
            size_scale     = c(10, 60),       # min/max bubble radius in pixels
            duration       = 17000L,          # total playback ms for one pass, larger numbers are slower movement
            label_size     = NULL,            # NULL = auto from entity count
            label_colour   = TRUE,            # labels match bubble colour
            trails         = TRUE,            # show trailing lines + ghost bubbles
            trail_length   = 4L,              # real time steps to trail back, can be set to the total num of rows of the data, e.g. nrow(gap_dslab)
            hover_focus    = c("group", "entity")[1],  # what hover highlights
            tooltip_follow = FALSE,           # TRUE = tip moves with bubble
            title          = "Gapminder — Health & Wealth of Nations",
            theme          = "default",       # any echarts4r theme name
            width          = "100%",
            height         = "600px")
```

### Key arguments

| Argument | Default | Description |
|---|---|---|
| `id` | — | Column identifying each entity (e.g. country) |
| `time` | — | Numeric time column (e.g. year) |
| `x`, `y` | — | Variables for the two axes |
| `size` | `NULL` | Bubble size variable; `NULL` = uniform |
| `color` | `NULL` | Categorical grouping for colour; `NULL` = single colour |
| `x_log` | `TRUE` | Log scale on x axis |
| `duration` | `17000` | Milliseconds for one full animation pass |
| `trails` | `TRUE` | Show fading trail lines and ghost bubbles |
| `trail_length` | `4` | How many real time steps to trail back |
| `hover_focus` | `"group"` | `"group"` highlights the hovered entity's whole group; `"entity"` highlights only the hovered entity |
| `tooltip_follow` | `FALSE` | `TRUE` makes the info box track the moving bubble |
| `label_size` | `NULL` | Font size in px for entity labels; `NULL` = auto-sized by entity count; adjustable at runtime with A- / A+ buttons |

### Themes

Any echarts4r theme name: `"default"`, `"dark"`, `"vintage"`, `"westeros"`,
`"essos"`, `"wonderland"`, `"walden"`, `"chalk"`, `"infographic"`,
`"macarons"`, `"roma"`, `"shine"`, `"purple-passion"`, `"halloween"`.

---

## Control Bar

The chart renders a control bar below the plot with:

| Control | Function |
|---|---|
| ▶ / ⏸ | Play / Pause |
| Slider | Scrub to any time position |
| Year readout | Shows current interpolated time |
| **Trails ON/OFF** | Toggle trail lines and ghost bubbles |
| **A- / n / A+** | Decrease / show / increase label font size |

---

## Interaction

| Action | Effect |
|---|---|
| Hover over bubble | Highlights that entity's group (or entity only if `hover_focus = "entity"`); others hide |
| Move off bubble | Restores all entities |
| Click bubble | Locks the highlight; info box stays pinned |
| Click same bubble again | Releases the lock |
| Click empty chart area | Releases the lock |
| Click legend item | Toggles that group on/off; trails follow |  # This can only be used when the slider (time) is paused.

---

## Helper Functions

```r
# Load the classic Gapminder dataset (auto-installs gapminder package if needed)
gap_dslabs <- load_gapminder_dslabs()
```

---

## Dependencies

- [echarts4r](https://echarts4r.john-coene.com/) (>= 0.4.0)
- dplyr
- htmlwidgets
- jsonlite
- htmltools

Suggested: `gapminder`, `stringr`

---

## Background: Why ECharts?

ECharts was chosen over Plotly and gganimate for this use case because:

- Its `requestAnimationFrame`-based rendering engine produces genuinely smooth
  animation at ~60 fps
- It feels app-like rather than chart-like — closer to the original Gapminder
  experience
- The `echarts4r` package provides a solid, maintained R bridge
- Trail/ghost series, custom controls, and pinned tooltips are all achievable
  with direct JSON option injection via `e_list()` and `htmlwidgets::onRender()`

---

## License

MIT © John R. Wallace
