# motionChart.R
# A flash-free replacement for googleVis::gvisMotionChart using echarts4r.
#
# Architecture: all real data is passed to the browser once as compact JSON.
# A JavaScript requestAnimationFrame loop interpolates between real time steps
# client-side and calls echartsInstance.setOption() to update point positions.
#
# Author:  John R. Wallace
# License: MIT
# Depends: echarts4r (>= 0.4.0), dplyr, htmlwidgets, jsonlite

# ── main function ─────────────────────────────────────────────────────────────

#' Motion Chart - Flash-Free Animated Bubble Chart
#'
#' A drop-in replacement for \code{googleVis::gvisMotionChart} built on
#' \code{echarts4r} and Apache ECharts.  Renders smooth, interactive animated
#' bubble charts driven by a JavaScript \code{requestAnimationFrame} loop with
#' client-side interpolation between real data time steps.  No Flash, no browser
#' plugin, no data uploaded anywhere.
#'
#' @param data          Data frame in long format (one row per entity per time step).
#' @param id            Column name (string) for the entity identifier (e.g. \code{"country"}).
#' @param time          Column name (string) for the time variable.  Must be numeric.
#' @param x             Column name (string) for the x-axis variable.
#' @param y             Column name (string) for the y-axis variable.
#' @param size          Column name (string) for bubble size.  \code{NULL} = uniform size.
#' @param color         Column name (string) for categorical colour grouping.
#'                      \code{NULL} = single colour.
#' @param x_log         Logical.  Use log scale on x-axis?  Default \code{TRUE}.
#' @param y_log         Logical.  Use log scale on y-axis?  Default \code{FALSE}.
#' @param x_label       X-axis label string.  \code{NULL} = auto title-case of column name.
#' @param y_label       Y-axis label string.  \code{NULL} = auto title-case of column name.
#' @param time_label    Time axis label string.  \code{NULL} = auto title-case of column name.
#' @param size_scale    Length-2 numeric vector: min and max bubble radius in pixels.
#'                      Default \code{c(10, 60)}.
#' @param duration      Total playback duration in milliseconds for one full pass through
#'                      all time steps.  Default \code{17000}.
#' @param label_size    Integer font size in pixels for entity labels.  \code{NULL} =
#'                      auto-selected based on entity count.  Can be adjusted at runtime
#'                      with the A- / A+ buttons in the control bar.
#' @param label_colour  Logical.  If \code{TRUE} (default), entity labels are coloured to
#'                      match their bubble.  If \code{FALSE}, all labels render in dark grey.
#' @param trails        Logical.  Show fading trail lines and ghost bubbles behind each
#'                      entity?  Default \code{TRUE}.
#' @param trail_length  Integer.  Number of real time steps to trail back.  Default \code{4}.
#' @param hover_focus   Character.  Controls what is highlighted when hovering over a bubble.
#'                      \code{"group"} (default) highlights all entities in the same group.
#'                      \code{"entity"} highlights only the hovered entity.
#'                      Use the indexed form \code{c("group", "entity")[1]} to make the
#'                      options self-documenting - change the index to switch.
#' @param tooltip_follow Logical.  If \code{FALSE} (default), the info box is pinned to the
#'                      upper-right of the chart area.  If \code{TRUE}, the info box moves
#'                      smoothly with the selected bubble.
#' @param title         Optional chart title string.
#' @param theme         echarts4r theme name.  One of \code{"default"}, \code{"dark"},
#'                      \code{"vintage"}, \code{"westeros"}, \code{"essos"},
#'                      \code{"wonderland"}, \code{"walden"}, \code{"chalk"},
#'                      \code{"infographic"}, \code{"macarons"}, \code{"roma"},
#'                      \code{"shine"}, \code{"purple-passion"}, \code{"halloween"}.
#'                      Default \code{"default"}.
#' @param width         Widget width as a CSS string.  Default \code{"100\%"}.
#' @param height        Widget height as a CSS string.  Default \code{"600px"}.
#'
#' @return An \code{echarts4r} / \code{htmlwidget} object suitable for display in the
#'   RStudio Viewer, Shiny apps, R Markdown documents, and Quarto documents.
#'
#' @details
#' \strong{Animation:} all interpolation between real data time steps is performed
#' client-side in JavaScript via a \code{requestAnimationFrame} loop.  Data is
#' serialised to compact JSON once and embedded in the widget; no data is sent to
#' any server.
#'
#' \strong{Fixed axes:} global min/max are computed in R across every time step and
#' passed to ECharts as explicit axis bounds, so axes never rescale during playback.
#'
#' \strong{Trails:} when \code{trails = TRUE}, each entity's recent path is shown as
#' a fading polyline plus ghost bubbles (bright and full-size nearest the current
#' position, fading and shrinking toward the tail).  Trails respect legend filtering
#' and hover/click selection.
#'
#' \strong{Interaction:}
#' \itemize{
#'   \item Hover a bubble to highlight its group (or entity if \code{hover_focus = "entity"}).
#'   \item Click a bubble to lock the highlight; click again or click empty space to release.
#'   \item Click legend items to toggle groups on/off.
#'   \item Use A- / A+ buttons to adjust label size without re-running R.
#'   \item Use the Trails ON/OFF button to toggle trail display.
#' }
#'
#' @examples
#' \dontrun{
#' gap_dslabs <- load_gapminder_dslabs()
#'
#' motionChart(gap_dslabs,
#'             id             = "country",
#'             time           = "year",
#'             x              = "gdpPercap",
#'             y              = "lifeExp",
#'             size           = "pop",
#'             color          = "continent",
#'             x_log          = TRUE,
#'             duration       = 17000,
#'             trails         = TRUE,
#'             trail_length   = 4,
#'             hover_focus    = c("group", "entity")[1],
#'             tooltip_follow = FALSE,
#'             label_colour   = TRUE,
#'             title          = "Gapminder - Health & Wealth of Nations")
#' }
#'
#' @export
motionChart <- function(data,
                        id,
                        time,
                        x,
                        y,
                        size       = NULL,
                        color      = NULL,
                        x_log      = TRUE,
                        y_log      = FALSE,
                        x_label    = NULL,
                        y_label    = NULL,
                        time_label = NULL,
                        size_scale    = c(10, 60),
                        duration      = 17000L,
                        label_size    = NULL,
                        label_colour  = TRUE,
                        trails        = TRUE,
                        trail_length  = 4L,
                        hover_focus   = c("group", "entity")[1],
                        tooltip_follow = FALSE,
                        title         = NULL,
                        theme      = "default",
                        width      = "100%",
                        height     = "600px") {
                        
    
  # ── dependencies ─────────────────────────────────────────────────────────────
  for (pkg in c("echarts4r", "dplyr", "htmlwidgets", "jsonlite", "htmltools")) {
    if (!requireNamespace(pkg, quietly = TRUE))
      stop(sprintf("Install %s:  install.packages('%s')", pkg, pkg))
  }
  
  require(echarts4r)
  require(dplyr)
  
  
  # ── axis range helper ─────────────────────────────────────────────────────────
  
  # Compute stable, nicely-rounded axis bounds across all time steps
  #
  # For log axes, bounds are rounded to the nearest "nice" power-of-10 step
  # (floor for min, ceiling for max) so tick labels are clean integers.
  # For linear axes, bounds are floored/ceilinged to a round number whose
  # magnitude matches the data range.
  #
  # @param vals   Numeric vector of all values for one axis across every time step.
  # @param log    Logical. Is this a log-scale axis?
  # @param pad    Extra padding: log-space decades (log) or range fraction (linear).
  # @return Named list with \code{min} and \code{max}.
  axis_bounds <- function(vals, log = FALSE, pad = 0.05) {
    if (log) {
      vals <- vals[is.finite(vals) & vals > 0]
    } else {
      vals <- vals[is.finite(vals)]
    }
    lo <- min(vals, na.rm = TRUE)
    hi <- max(vals, na.rm = TRUE)
  
    if (log) {
      # Round outward to whole decades (integer log10) so bounds always land on
      # clean powers of 10: 100, 1000, 10000 etc.  Half-decade steps like 3162
      # are valid mathematically but ECharts can't place a clean tick label there.
      log_lo  <- log10(lo) - pad
      log_hi  <- log10(hi) + pad
      nice_lo <- floor(log_lo)      # whole decade floor
      nice_hi <- ceiling(log_hi)    # whole decade ceiling
      list(min = 10^nice_lo, max = 10^nice_hi)
    } else {
      rng       <- hi - lo
      padded_lo <- lo - pad * rng
      padded_hi <- hi + pad * rng
      magnitude <- 10^floor(log10(max(abs(rng), 1e-9)))
      step      <- magnitude / 2
      nice_lo   <- floor(padded_lo   / step) * step
      nice_hi   <- ceiling(padded_hi / step) * step
      # If all data values are non-negative, never let the axis go below 0
      if (lo >= 0) nice_lo <- max(nice_lo, 0)
      list(min = nice_lo, max = nice_hi)
    }
  }
  
  
  # ── auto label-size helper ────────────────────────────────────────────────────
  
  # Choose a default label font size based on entity count
  #
  # Fewer entities give larger labels; crowded charts give smaller labels.
  # The user can always override interactively with the A- / A+ buttons.
  #
  # @param n Integer number of entities.
  # @return Integer font size in pixels.
  auto_label_size <- function(n) {
    if      (n <=  10) 19L
    else if (n <=  20) 18L
    else if (n <=  40) 17L
    else if (n <=  80) 16L
    else if (n <= 140) 15L
    else               14L
  }
                      

  # ── 0. validate ────────────────────────────────────────────────────────────
  stopifnot(is.data.frame(data))
  for (col in c(id, time, x, y))
    if (!col %in% names(data)) stop("Column not found: ", col)
  if (!is.null(size)  && !size  %in% names(data)) stop("size column not found: ",  size)
  if (!is.null(color) && !color %in% names(data)) stop("color column not found: ", color)
  hover_focus <- match.arg(hover_focus, c("group", "entity"))

  # Apply str_to_title to default labels so "gdpPercap" → "GdpPercap",
  # "lifeExp" → "LifeExp", "year" → "Year".  Explicit values are used as-is.
  if (!requireNamespace("stringr", quietly = TRUE)) {
    # base R fallback if stringr not available
    title_case <- function(s) paste0(toupper(substr(s, 1, 1)), substr(s, 2, nchar(s)))
  } else {
    title_case <- stringr::str_to_title
  }
  if (is.null(x_label))    x_label    <- title_case(x)
  if (is.null(y_label))    y_label    <- title_case(y)
  if (is.null(time_label)) time_label <- title_case(time)

  # ── 1. select & arrange ────────────────────────────────────────────────────
  df <- data %>%
    dplyr::select(dplyr::all_of(c(id, time, x, y, size, color))) %>%
    dplyr::arrange(.data[[time]], .data[[id]])

  # ── 2. colour groups ───────────────────────────────────────────────────────
  if (!is.null(color)) {
    groups <- as.character(sort(unique(df[[color]])))
  } else {
    df$.group <- "All"
    color     <- ".group"
    groups    <- "All"
  }

  # ── 3. size normalisation (global across all time steps) ──────────────────
  if (!is.null(size)) {
    s_vals <- df[[size]]
    s_min  <- min(s_vals, na.rm = TRUE)
    s_max  <- max(s_vals, na.rm = TRUE)
    df$.size_px <- size_scale[1] +
      (s_vals - s_min) / (s_max - s_min + .Machine$double.eps) *
      (size_scale[2] - size_scale[1])
  } else {
    df$.size_px <- mean(size_scale)
  }

  # ── 4. fixed axis bounds (computed once across ALL time steps) ────────────
  x_bounds <- axis_bounds(df[[x]], log = x_log)
  y_bounds <- axis_bounds(df[[y]], log = y_log)

  # ── smart decimal places for tooltip ─────────────────────────────────────
  # Decimal places are needed only when values are small (< 1).
  # For values >= 1, integers or 1 decimal is sufficient.
  # Logic: find the smallest non-zero positive value; if it is < 1 then
  # use enough decimals to show it, driven by its log10 magnitude.
  # Examples:
  #   gdpPercap  (min ~241,   max ~113k) -> 0 decimals
  #   lifeExp    (min ~23,    max ~83)   -> 0 decimals
  #   fertility  (min ~1.2,   max ~8)    -> 1 decimal
  #   proportion (min ~0.03,  max ~0.9)  -> 2 decimals
  #   tiny vals  (min ~0.000005)         -> 6 decimals
  smart_decimals <- function(vals) {
    vals <- vals[is.finite(vals) & vals > 0]
    if (length(vals) == 0) return(1L)
    min_val <- min(vals)
    if (min_val >= 10)  return(0L)
    if (min_val >= 1)   return(1L)
    as.integer(ceiling(abs(log10(min_val))))
  }
  x_decimals <- smart_decimals(df[[x]])
  y_decimals <- smart_decimals(df[[y]])
  n_entities <- length(unique(df[[id]]))
  init_label_size <- if (!is.null(label_size)) as.integer(label_size)
                     else auto_label_size(n_entities)

  # ── 6. build entity list for JS ───────────────────────────────────────────
  time_steps <- sort(unique(df[[time]]))
  entity_ids <- sort(unique(df[[id]]))

  entity_list <- lapply(entity_ids, function(eid) {
    rows <- df[as.character(df[[id]]) == as.character(eid), , drop = FALSE]
    rows <- rows[order(rows[[time]]), ]
    list(
      id     = as.character(eid),
      group  = as.character(rows[[color]][1]),
      frames = lapply(seq_len(nrow(rows)), function(i)
        list(t = rows[[time]][i],
             x = rows[[x]][i],
             y = rows[[y]][i],
             r = rows$.size_px[i]))
    )
  })

  # ── 7. initial ECharts option ─────────────────────────────────────────────
  # When label_colour = TRUE we pass color:"inherit" — ECharts will use the
  # series colour automatically.  "inherit" is the ECharts keyword for this.
  label_color_val <- if (isTRUE(label_colour)) "inherit" else "#555"

  # ── ECharts 5 default palette ─────────────────────────────────────────────
  # Assign colours explicitly in R so every series type (bubble, trail line,
  # trail ghost) gets the exact same colour for its group.  This is the only
  # reliable approach — reading colours back from the rendered chart is fragile.
  echarts_palette <- c("#5470c6","#91cc75","#fac858","#ee6666","#73c0de",
                       "#3ba272","#fc8452","#9a60b4","#ea7ccc")
  group_colors <- setNames(
    echarts_palette[((seq_along(groups) - 1) %% length(echarts_palette)) + 1],
    groups
  )

  # ── bubble series (one per group) ─────────────────────────────────────────
  bubble_series <- lapply(groups, function(grp) {
    list(
      name       = grp,
      type       = "scatter",
      color      = group_colors[[grp]],
      symbolSize = htmlwidgets::JS("function(v){ return v[2]; }"),
      emphasis   = list(disabled = TRUE),   # we handle highlight ourselves
      blur       = list(itemStyle = list(opacity = 1)),  # prevent ECharts dimming
      label      = list(
        show      = TRUE,
        formatter = htmlwidgets::JS("function(p){ return p.name; }"),
        position  = "right",
        fontSize  = init_label_size,
        color     = label_color_val
      ),
      data = list()
    )
  })

  # ── trail line series (one per group) ─────────────────────────────────────
  trail_line_series <- lapply(groups, function(grp) {
    list(
      name            = paste0(".trail_line_", grp),
      type            = "line",
      color           = group_colors[[grp]],
      showSymbol      = FALSE,
      silent          = TRUE,
      legendHoverLink = FALSE,
      lineStyle       = list(width = 1.5, type = "solid", opacity = 0.5),
      label           = list(show = FALSE),
      emphasis        = list(disabled = TRUE),
      data            = list()
    )
  })

  # ── trail ghost series (one per group) ────────────────────────────────────
  trail_ghost_series <- lapply(groups, function(grp) {
    list(
      name            = paste0(".trail_ghost_", grp),
      type            = "scatter",
      color           = group_colors[[grp]],
      silent          = TRUE,
      legendHoverLink = FALSE,
      symbolSize      = htmlwidgets::JS("function(v){ return v[2]; }"),
      label           = list(show = FALSE),
      emphasis        = list(disabled = TRUE),
      data            = list()
    )
  })

  base_series <- c(trail_line_series, trail_ghost_series, bubble_series)

  echart_option <- list(
    animation = FALSE,
    title = if (!is.null(title))
              list(text = as.character(title), left = "center", top = 8)
            else list(),
    tooltip = list(show = FALSE),
    legend = list(show = FALSE),   # replaced by custom Color panel in JS

    # ── fixed x axis ────────────────────────────────────────────────────────
    # min/max are passed as JS functions rather than raw numbers.
    # ECharts calls function(v){} with v.min / v.max = the data extent, and
    # whatever we return becomes the axis bound.  Returning our pre-computed
    # nice value as a *floor/ceiling* of that extent means ECharts' own tick
    # generator sees the full intended range and rounds tick labels cleanly —
    # the community-standard fix for the "max value not rounded" issue.
    xAxis = list(
      type         = if (x_log) "log" else "value",
      min          = htmlwidgets::JS(sprintf("function(v){ return %s; }", x_bounds$min)),
      max          = htmlwidgets::JS(sprintf("function(v){ return %s; }", x_bounds$max)),
      name         = x_label,
      nameGap      = 36,
      nameLocation = "middle",
      nameTextStyle = list(fontSize = 15),
      splitLine    = list(show = FALSE),
      axisLabel    = list(fontSize = 13),
      axisLine     = list(lineStyle = list(width = 2)),
      axisTick     = list(lineStyle = list(width = 2))
    ),

    # ── fixed y axis ────────────────────────────────────────────────────────
    yAxis = list(
      type         = if (y_log) "log" else "value",
      min          = htmlwidgets::JS(sprintf("function(v){ return %s; }", y_bounds$min)),
      max          = htmlwidgets::JS(sprintf("function(v){ return %s; }", y_bounds$max)),
      name         = y_label,
      nameGap      = 48,
      nameLocation = "middle",
      nameTextStyle = list(fontSize = 15),
      splitLine    = list(lineStyle = list(type = "dashed")),
      axisLabel    = list(fontSize = 13),
      axisLine     = list(lineStyle = list(width = 2)),
      axisTick     = list(lineStyle = list(width = 2))
    ),

    grid   = list(top = 80, bottom = 100, left = 80, right = 220),
    series = base_series
  )

  # ── 8. build widget ────────────────────────────────────────────────────────
  widget <- e_charts(width = width, height = height) |>
    e_theme(theme) |>
    e_list(echart_option) 
    
  # ── 9. JS animation + controls ────────────────────────────────────────────
  # Use paste0() rather than sprintf() so that % in CSS (width:100%) and any
  # Unicode characters in the JS string are never misread as format specifiers.
  # R values are injected as named placeholders replaced via gsub().

  js_template <- '
function(el, x) {

  // ── get echarts instance ───────────────────────────────────────────────
  var chart = echarts.getInstanceByDom(el);
  if (!chart) {
    console.error("motionChart: could not get echarts instance");
    return;
  }

  // ── embedded data ──────────────────────────────────────────────────────
  var entities      = __ENTITIES__;
  var timeSteps     = __TIMESTEPS__;
  var groups        = __GROUPS__;
  var groupColors   = __GROUPCOLORS__;  // injected from R — index matches groups[]
  var duration      = __DURATION__;
  var timeName      = "__TIMENAME__";
  var labelFontSize = __LABELSIZE__;    // mutable via A-/A+ buttons
  var labelColour   = __LABELCOLOUR__;  // true = inherit series colour
  var showTrails    = __TRAILS__;       // mutable via Trails button
  var trailLength   = __TRAILLENGTH__;  // real time steps to trail back
  var hoverFocus    = __HOVERFOCUS__;   // "group" or "entity"
  var tooltipFollow = __TOOLTIPFOLLOW__; // true = tip moves with bubble, false = upper right
  var x_label_js    = "__XLABEL__";
  var y_label_js    = "__YLABEL__";
  var x_decimals    = __XDECIMALS__;
  var y_decimals    = __YDECIMALS__;

  // ── pinned tooltip div ────────────────────────────────────────────────
  // A custom div that tracks the active bubble — avoids ECharts showTip
  // feedback loop that causes flickering.
  var pinnedTip = document.createElement("div");
  pinnedTip.style.cssText = [
    "position:absolute", "display:none", "pointer-events:none",
    "top:90px", "right:226px",
    "background:rgba(255,255,255,0.96)",
    "color:#333",
    "border:1px solid #ccc",
    "padding:6px 10px", "border-radius:4px",
    "font-size:13px", "font-family:sans-serif",
    "line-height:1.5", "white-space:nowrap",
    "width:fit-content",
    "box-sizing:content-box", "z-index:9999",
    "box-shadow:0 2px 8px rgba(0,0,0,0.15)"
  ].join(";");
  var tipContainer = el.parentNode || el;
  tipContainer.style.position = "relative";
  tipContainer.appendChild(pinnedTip);

  // ── series index maps ──────────────────────────────────────────────────
  // Series order in base_series: trail_line × nGroups, trail_ghost × nGroups,
  // bubble × nGroups — must match the order built in R.
  var nGroups = groups.length;
  var grpIdx  = {};
  for (var g = 0; g < nGroups; g++) grpIdx[groups[g]] = g;

  function trailLineIdx(g)  { return g; }
  function trailGhostIdx(g) { return nGroups + g; }
  function bubbleIdx(g)     { return nGroups * 2 + g; }

  // ── build control bar ─────────────────────────────────────────────────
  var ctrlDiv = document.createElement("div");
  ctrlDiv.style.cssText = [
    "display:flex", "align-items:center", "gap:6px",
    "padding:4px 80px 4px 80px",
    "box-sizing:border-box", "width:100%",
    "font-family:sans-serif"
  ].join(";");

  // play/pause — pause uses inline SVG for slim proportions since the Unicode
  // pause character is too wide/squatty on most system fonts.
  var PLAY_HTML  = "&#9654;";
  var PAUSE_HTML = \'<svg width="12" height="16" viewBox="0 0 12 16" style="vertical-align:middle">\' +
                   \'<rect x="1" y="1" width="3" height="12" rx="1" fill="currentColor"/>\' +
                   \'<rect x="7" y="1" width="3" height="12" rx="1" fill="currentColor"/>\' +
                   \'</svg>\';

  var playBtn = document.createElement("button");
  playBtn.innerHTML = PLAY_HTML;
  playBtn.title     = "Play / Pause";
  playBtn.style.cssText = "font-size:18px;border:none;background:none;cursor:pointer;padding:0 4px;flex-shrink:0;line-height:1;";

  // scrubber
  var slider = document.createElement("input");
  slider.type  = "range";
  slider.min   = "0";
  slider.max   = "10000";
  slider.value = "0";
  slider.style.cssText = "flex:1;cursor:pointer;";

  // time readout
  var timeLabel = document.createElement("span");
  timeLabel.style.cssText = "font-size:13px;min-width:50px;text-align:right;white-space:nowrap;color:#888;";
  timeLabel.textContent   = String(timeSteps[0]);

  // Trails toggle button
  var trailsBtn = document.createElement("button");
  trailsBtn.title = "Toggle trails";
  function updateTrailsBtn() {
    trailsBtn.textContent = showTrails ? "Trails ON" : "Trails OFF";
    trailsBtn.style.cssText = [
      "font-size:12px", "border:1px solid #ccc", "border-radius:3px",
      "cursor:pointer", "padding:1px 7px", "flex-shrink:0",
      showTrails ? "background:#d4ecd4;color:#1a6e1a;"
                 : "background:#f8f8f8;color:#999;"
    ].join(";");
  }
  updateTrailsBtn();

  // font-size label
  var fsLabel = document.createElement("span");
  fsLabel.style.cssText = "font-size:11px;color:#666;white-space:nowrap;";
  fsLabel.textContent   = "Label px";

  // A- button
  var btnSmaller = document.createElement("button");
  btnSmaller.textContent = "A-";
  btnSmaller.title       = "Decrease label size";
  btnSmaller.style.cssText = "font-size:13px;border:1px solid #ccc;border-radius:3px;background:#f8f8f8;cursor:pointer;padding:1px 6px;flex-shrink:0;";

  // font size readout
  var fsReadout = document.createElement("span");
  fsReadout.style.cssText = "font-size:12px;min-width:22px;text-align:center;";
  fsReadout.textContent   = String(labelFontSize);

  // A+ button
  var btnLarger = document.createElement("button");
  btnLarger.textContent = "A+";
  btnLarger.title       = "Increase label size";
  btnLarger.style.cssText = "font-size:13px;border:1px solid #ccc;border-radius:3px;background:#f8f8f8;cursor:pointer;padding:1px 6px;flex-shrink:0;";

  ctrlDiv.appendChild(playBtn);
  ctrlDiv.appendChild(slider);
  ctrlDiv.appendChild(timeLabel);
  ctrlDiv.appendChild(trailsBtn);
  ctrlDiv.appendChild(fsLabel);
  ctrlDiv.appendChild(btnSmaller);
  ctrlDiv.appendChild(fsReadout);
  ctrlDiv.appendChild(btnLarger);

  if (el.parentNode) {
    el.parentNode.insertBefore(ctrlDiv, el.nextSibling);
  }

  // ── helpers ────────────────────────────────────────────────────────────
  function lerp(a, b, t) { return a + (b - a) * t; }

  // ── legend / click-highlight state ────────────────────────────────────
  var legendSelected  = {};
  var highlightedName = null;   // set by click — persists until clicked again
  var hoverName       = null;   // set by mouseover — cleared on mouseout
  var hoverGroup      = null;   // group of hovered entity (for "group" mode)
  for (var g = 0; g < nGroups; g++) legendSelected[groups[g]] = true;

  // ── entity visibility state (individual checkboxes) ───────────────────
  var entityVisible = {};
  for (var ei = 0; ei < entities.length; ei++) entityVisible[entities[ei].id] = true;

  // ── right-side panel column ────────────────────────────────────────────
  // A single absolute-positioned column containing two collapsible sub-panels:
  //   [Color]      — one checkbox row per group, with color swatch
  //   [Categories] — one checkbox row per entity, scrollable
  // The ECharts built-in legend is hidden; this replaces it entirely.

  var PANEL_BTN_CSS = [
    "font-size:11px", "padding:1px 6px",
    "border:1px solid #ccc", "border-radius:3px",
    "background:#f0f0f0", "cursor:pointer", "color:#333"
  ].join(";");

  // Helper: build a collapsible sub-panel.
  // Returns { outer, body } where body is the scrollable content div.
  function makeSubPanel(titleText, maxBodyPx) {
    var outer = document.createElement("div");
    outer.style.cssText = [
      "display:flex", "flex-direction:column",
      "border-bottom:1px solid #ddd",
      "flex-shrink:0",
      "min-height:0"
    ].join(";");

    // ── title bar (click to collapse/expand) ──────────────────────────
    var titleBar = document.createElement("div");
    titleBar.style.cssText = [
      "display:flex", "align-items:center", "justify-content:space-between",
      "padding:4px 8px 3px 8px",
      "cursor:pointer", "user-select:none",
      "border-bottom:1px solid #ddd",
      "flex-shrink:0"
    ].join(";");

    var titleSpan = document.createElement("span");
    titleSpan.textContent = titleText;
    titleSpan.style.cssText = "font-weight:600;font-size:12px;color:#444;";

    var chevron = document.createElement("span");
    chevron.textContent = "v";   // collapse indicator — rotated via CSS when collapsed
    chevron.style.cssText = "font-size:10px;color:#888;transition:transform 0.15s;font-weight:bold;";

    titleBar.appendChild(titleSpan);
    titleBar.appendChild(chevron);
    outer.appendChild(titleBar);

    // ── select-all / deselect-all row ─────────────────────────────────
    var selRow = document.createElement("div");
    selRow.style.cssText = "display:flex;gap:4px;padding:3px 8px 3px 8px;flex-shrink:0;";
    outer.appendChild(selRow);

    // ── scrollable body ───────────────────────────────────────────────
    var body = document.createElement("div");
    body.style.cssText = [
      "overflow-y:auto",
      "padding:2px 0",
      "max-height:" + maxBodyPx + "px"
    ].join(";");
    outer.appendChild(body);

    // collapse/expand toggle
    var collapsed = false;
    function toggleCollapse() {
      collapsed = !collapsed;
      selRow.style.display = collapsed ? "none" : "flex";
      body.style.display   = collapsed ? "none" : "block";
      chevron.style.transform = collapsed ? "rotate(-90deg)" : "rotate(0deg)";
    }
    titleBar.addEventListener("click", toggleCollapse);

    return { outer: outer, body: body, selRow: selRow };
  }

  // ── outer column wrapper ──────────────────────────────────────────────
  var sideColumn = document.createElement("div");
  sideColumn.style.cssText = [
    "position:absolute",
    "top:0", "right:0",
    "width:190px",
    "bottom:33px",
    "display:flex", "flex-direction:column",
    "font-family:sans-serif", "font-size:12px",
    "border-left:1px solid #ddd",
    "box-sizing:border-box",
    "background:rgba(255,255,255,0.97)",
    "z-index:100",
    "overflow:hidden"
  ].join(";");

  // ── COLOR sub-panel ───────────────────────────────────────────────────
  var colorSub = makeSubPanel("Color", 200);

  // Select all / Deselect all for Color
  var cBtnAll = document.createElement("button");
  cBtnAll.textContent = "Select all";
  cBtnAll.style.cssText = PANEL_BTN_CSS;
  var cBtnNone = document.createElement("button");
  cBtnNone.textContent = "Deselect all";
  cBtnNone.style.cssText = PANEL_BTN_CSS;
  colorSub.selRow.appendChild(cBtnAll);
  colorSub.selRow.appendChild(cBtnNone);

  // One checkbox row per group
  var colorCheckMap = {};   // group → <input>
  for (var gi2 = 0; gi2 < groups.length; gi2++) {
    var grp    = groups[gi2];
    var gcol   = groupColors[gi2] || "#888";

    var crow = document.createElement("label");
    crow.style.cssText = [
      "display:flex", "align-items:center", "gap:6px",
      "padding:2px 8px",
      "cursor:pointer", "white-space:nowrap", "overflow:hidden"
    ].join(";");
    crow.title = grp;

    var ccb = document.createElement("input");
    ccb.type    = "checkbox";
    ccb.checked = true;
    ccb.style.cssText = "margin:0;flex-shrink:0;accent-color:" + gcol + ";cursor:pointer;";

    // Color swatch square
    var swatch = document.createElement("span");
    swatch.style.cssText = [
      "display:inline-block",
      "width:10px", "height:10px",
      "border-radius:2px",
      "background:" + gcol,
      "flex-shrink:0"
    ].join(";");

    var glbl = document.createElement("span");
    glbl.textContent = grp;
    glbl.style.cssText = "font-size:11px;color:#333;overflow:hidden;text-overflow:ellipsis;";

    crow.appendChild(ccb);
    crow.appendChild(glbl);
    colorSub.body.appendChild(crow);
    colorCheckMap[grp] = ccb;

    (function(groupName) {
      ccb.addEventListener("change", function() {
        legendSelected[groupName] = this.checked;
        // Sync: dim category rows belonging to this group
        updateCategoryRowDimming();
        renderFrame(parseFloat(slider.value) / 10000);
      });
    })(grp);
  }

  sideColumn.appendChild(colorSub.outer);

  // Color Select All / Deselect All
  cBtnAll.addEventListener("click", function() {
    for (var g2 = 0; g2 < groups.length; g2++) {
      legendSelected[groups[g2]] = true;
      if (colorCheckMap[groups[g2]]) colorCheckMap[groups[g2]].checked = true;
    }
    updateCategoryRowDimming();
    renderFrame(parseFloat(slider.value) / 10000);
  });
  cBtnNone.addEventListener("click", function() {
    for (var g2 = 0; g2 < groups.length; g2++) {
      legendSelected[groups[g2]] = false;
      if (colorCheckMap[groups[g2]]) colorCheckMap[groups[g2]].checked = false;
    }
    updateCategoryRowDimming();
    renderFrame(parseFloat(slider.value) / 10000);
  });

  // ── CATEGORIES sub-panel ──────────────────────────────────────────────
  // Takes the remaining vertical space via flex:1 on its outer div
  var catSub = makeSubPanel("Categories", 99999);  // no hard cap; flex handles it
  catSub.body.style.maxHeight = "";    // remove the cap set in makeSubPanel
  catSub.body.style.flex      = "1";   // fill remaining space in the column
  catSub.outer.style.flex     = "1";   // outer also grows
  catSub.outer.style.minHeight = "0";  // needed for flex children to shrink

  // Select all / Deselect all for Categories
  var eBtnAll = document.createElement("button");
  eBtnAll.textContent = "Select all";
  eBtnAll.style.cssText = PANEL_BTN_CSS;
  var eBtnNone = document.createElement("button");
  eBtnNone.textContent = "Deselect all";
  eBtnNone.style.cssText = PANEL_BTN_CSS;
  catSub.selRow.appendChild(eBtnAll);
  catSub.selRow.appendChild(eBtnNone);

  // One checkbox row per entity
  var checkboxMap = {};      // id → <input>
  var entityRowMap = {};     // id → label element (for dimming)
  for (var ei = 0; ei < entities.length; ei++) {
    var eid    = entities[ei].id;
    var egrp   = entities[ei].group;
    var ecolor = groupColors[grpIdx[egrp]] || "#888";

    var row = document.createElement("label");
    row.style.cssText = [
      "display:flex", "align-items:center", "gap:5px",
      "padding:1px 8px",
      "cursor:pointer", "white-space:nowrap", "overflow:hidden"
    ].join(";");
    row.title = eid;

    var cb = document.createElement("input");
    cb.type    = "checkbox";
    cb.checked = true;
    cb.style.cssText = "margin:0;flex-shrink:0;accent-color:" + ecolor + ";cursor:pointer;";
    cb.dataset.entityId = eid;

    var lbl = document.createElement("span");
    lbl.textContent = eid;
    lbl.style.cssText = "font-size:11px;color:#333;overflow:hidden;text-overflow:ellipsis;";

    row.appendChild(cb);
    row.appendChild(lbl);
    catSub.body.appendChild(row);
    checkboxMap[eid]   = cb;
    entityRowMap[eid]  = row;

    (function(entityId) {
      cb.addEventListener("change", function() {
        entityVisible[entityId] = this.checked;
        renderFrame(parseFloat(slider.value) / 10000);
      });
    })(eid);
  }

  sideColumn.appendChild(catSub.outer);

  // Dim category rows whose color group is currently deselected
  function updateCategoryRowDimming() {
    for (var ei2 = 0; ei2 < entities.length; ei2++) {
      var eid2  = entities[ei2].id;
      var egrp2 = entities[ei2].group;
      var rowEl = entityRowMap[eid2];
      if (!rowEl) continue;
      rowEl.style.opacity = legendSelected[egrp2] ? "1" : "0.35";
    }
  }

  // Mount the column
  var chartContainer = el.parentNode || el;
  chartContainer.style.position = "relative";
  chartContainer.appendChild(sideColumn);

  // Categories Select All / Deselect All
  eBtnAll.addEventListener("click", function() {
    for (var ei = 0; ei < entities.length; ei++) {
      var eid = entities[ei].id;
      entityVisible[eid] = true;
      if (checkboxMap[eid]) checkboxMap[eid].checked = true;
    }
    renderFrame(parseFloat(slider.value) / 10000);
  });

  eBtnNone.addEventListener("click", function() {
    for (var ei = 0; ei < entities.length; ei++) {
      var eid = entities[ei].id;
      entityVisible[eid] = false;
      if (checkboxMap[eid]) checkboxMap[eid].checked = false;
    }
    renderFrame(parseFloat(slider.value) / 10000);
  });

  // Build entity-id -> group lookup for fast access in mouseover
  var entityGroupMap = {};
  for (var e = 0; e < entities.length; e++) {
    entityGroupMap[entities[e].id] = entities[e].group;
  }

  // Return interpolated {x,y,r} for entity at fractional timeline position prog.
  // Uses the actual time values stored in each frame rather than positional
  // indexing, so entities with irregular or late-starting data appear and
  // disappear at the correct times.
  function interpEntity(ent, prog) {
    var nFrames = ent.frames.length;
    if (nFrames === 0) return null;

    var maxIdx   = timeSteps.length - 1;
    var scaled   = Math.max(0, Math.min(1, prog)) * maxIdx;
    var idx0     = Math.min(Math.floor(scaled), maxIdx - 1);
    var idx1     = idx0 + 1;
    var alpha    = scaled - idx0;
    // Current time value (interpolated between two global time steps)
    var tNow     = timeSteps[idx0] + alpha * (timeSteps[idx1] - timeSteps[idx0]);

    var tFirst = ent.frames[0].t;
    var tLast  = ent.frames[nFrames - 1].t;

    // Entity has not appeared yet — hide it entirely
    if (tNow < tFirst) return null;

    // Entity data has ended — freeze at last known position
    if (tNow >= tLast) {
      var f = ent.frames[nFrames - 1];
      return { x: f.x, y: f.y, r: f.r };
    }

    // Binary search for the two frames bracketing tNow
    var lo = 0, hi = nFrames - 1;
    while (hi - lo > 1) {
      var mid = (lo + hi) >> 1;
      if (ent.frames[mid].t <= tNow) lo = mid; else hi = mid;
    }
    var f0 = ent.frames[lo];
    var f1 = ent.frames[hi];
    var span = f1.t - f0.t;
    var a    = (span > 0) ? (tNow - f0.t) / span : 0;
    return {
      x: f0.x + a * (f1.x - f0.x),
      y: f0.y + a * (f1.y - f0.y),
      r: f0.r + a * (f1.r - f0.r)
    };
  }

  // Build prog values for the trail steps behind current prog.
  function trailProgs(prog) {
    var maxIdx   = timeSteps.length - 1;
    var interval = 1.0 / maxIdx;
    var steps    = [];
    for (var s = 1; s <= trailLength; s++) {
      var tp = prog - s * interval;
      if (tp < 0) break;
      steps.push(tp);
    }
    return steps;   // nearest → oldest
  }

  function buildSeriesData(prog) {
    prog = Math.max(0, Math.min(1, prog));
    var maxIdx   = timeSteps.length - 1;
    var scaled   = prog * maxIdx;
    var idx0     = Math.min(Math.floor(scaled), maxIdx - 1);
    var idx1     = idx0 + 1;
    var alpha    = scaled - idx0;
    var tDisplay = lerp(timeSteps[idx0], timeSteps[idx1], alpha);

    var bubbleData = [];
    var lineData   = [];
    var ghostData  = [];
    for (var g = 0; g < nGroups; g++) {
      bubbleData.push([]);
      lineData.push({});
      ghostData.push([]);
    }

    var tSteps = showTrails ? trailProgs(prog) : [];

    for (var e = 0; e < entities.length; e++) {
      var ent = entities[e];
      var gi  = grpIdx[ent.group];
      if (gi === undefined) continue;
      if (!legendSelected[ent.group]) continue;
      if (!entityVisible[ent.id]) continue;

      var cur = interpEntity(ent, prog);
      if (!cur) continue;

      // Determine visibility: click state takes priority over hover state.
      // In "group" mode, hovering shows all entities in the hovered group.
      // In "entity" mode, hovering shows only the hovered entity.
      var isActive;
      if (highlightedName !== null) {
        // Click is locked — only the clicked entity is active
        isActive = (ent.id === highlightedName);
      } else if (hoverName !== null) {
        if (hoverFocus === "group") {
          isActive = (ent.group === hoverGroup);
        } else {
          isActive = (ent.id === hoverName);
        }
      } else {
        isActive = true;
      }

      // Active points are pushed normally; inactive points are omitted entirely
      // so ECharts has no data to hit-test against — tooltip cannot fire on them.
      if (isActive) {
        bubbleData[gi].push({
          name  : ent.id,
          value : [cur.x, cur.y, cur.r]
        });
      }

      // Only draw trails for active entities
      if (!showTrails || tSteps.length === 0) continue;
      if (!isActive) continue;

      var col      = groupColors[gi] || "#aaa";
      var polyline = [];

      for (var s = 0; s < tSteps.length; s++) {
        var tp  = tSteps[s];
        var pos = interpEntity(ent, tp);
        if (!pos) continue;

        // s=0 is nearest to bubble (brightest, largest)
        // s=tSteps.length-1 is oldest (most faded, smallest)
        var opacityFrac = s / Math.max(tSteps.length - 1, 1);  // 0=nearest → 1=oldest
        var opacity     = 0.55 - opacityFrac * 0.45;           // 0.55 → 0.10
        var ghostR      = pos.r * (0.95 - opacityFrac * 0.2);  // 0.95 → 0.75

        polyline.unshift([pos.x, pos.y]);   // oldest first for polyline order
        ghostData[gi].push({
          value     : [pos.x, pos.y, ghostR],
          itemStyle : { color: col, opacity: opacity, borderWidth: 0 }
        });
      }
      polyline.push([cur.x, cur.y]);
      lineData[gi][ent.id] = polyline;
    }

    var flatLineData = [];
    for (var g = 0; g < nGroups; g++) {
      var col  = groupColors[g] || "#aaa";
      var segs = [];
      var keys = Object.keys(lineData[g]);
      for (var k = 0; k < keys.length; k++) {
        var pts = lineData[g][keys[k]];
        for (var p = 0; p < pts.length; p++) segs.push({ value: pts[p] });
        segs.push({ value: [null, null] });
      }
      flatLineData.push({ segs: segs, color: col });
    }

    return {
      bubbleData:   bubbleData,
      flatLineData: flatLineData,
      ghostData:    ghostData,
      tDisplay:     tDisplay
    };
  }

  // ── render one frame ───────────────────────────────────────────────────
  function renderFrame(prog) {
    var fd = buildSeriesData(prog);

    var seriesUpdate = [];
    for (var g = 0; g < nGroups; g++) {
      seriesUpdate[trailLineIdx(g)] = {
        data      : fd.flatLineData[g].segs,
        lineStyle : { color: fd.flatLineData[g].color, width: 1.5, opacity: 0.5 }
      };
    }
    for (var g = 0; g < nGroups; g++) {
      // Per-point itemStyle in ghostData already carries color + opacity.
      // Setting opacity:1 at series level ensures ECharts does not dim the
      // whole series; individual point opacity then controls the fade effect.
      seriesUpdate[trailGhostIdx(g)] = {
        data      : fd.ghostData[g],
        opacity   : 1
      };
    }
    var lCol = labelColour ? "inherit" : "#555";
    for (var g = 0; g < nGroups; g++) {
      seriesUpdate[bubbleIdx(g)] = {
        data  : fd.bubbleData[g],
        label : { fontSize: labelFontSize, color: lCol }
      };
    }

    var pinnedName = highlightedName !== null ? highlightedName : hoverName;

    chart.setOption({
      title  : [{ subtext: timeName + ": " + Math.round(fd.tDisplay),
                  subtextStyle: { fontSize: 15, color: "#000" } }],
      series : seriesUpdate
    }, false);

    slider.value          = String(Math.round(prog * 10000));
    timeLabel.textContent = String(Math.round(fd.tDisplay));

    if (pinnedName !== null) {
      var found = null;
      for (var g = 0; g < nGroups; g++) {
        var bdata = fd.bubbleData[g];
        for (var di = 0; di < bdata.length; di++) {
          if (bdata[di].name === pinnedName) {
            found = { point: bdata[di], group: groups[g] };
            break;
          }
        }
        if (found) break;
      }
      if (found) {
        var xVal = found.point.value[0];
        var yVal = found.point.value[1];
        pinnedTip.innerHTML =
          "<b>" + found.group + "</b><br/>" +
          found.point.name + "<br/>" +
          x_label_js + ": " + xVal.toLocaleString(undefined, {minimumFractionDigits: x_decimals, maximumFractionDigits: x_decimals}) + "<br/>" +
          y_label_js + ": " + yVal.toLocaleString(undefined, {minimumFractionDigits: y_decimals, maximumFractionDigits: y_decimals});

        if (tooltipFollow) {
          var gi = grpIdx[found.group];
          var px = chart.convertToPixel({ seriesIndex: bubbleIdx(gi) },
                                        [xVal, yVal]);
          if (px) {
            // Place tip to the LEFT of the bubble so cursor does not cover it.
            // offsetWidth gives current rendered width; fall back to 160px.
            var tipW = pinnedTip.offsetWidth || 160;
            pinnedTip.style.left  = (px[0] - tipW - 10) + "px";
            pinnedTip.style.right = "auto";
            pinnedTip.style.top   = (px[1] - 10) + "px";
          }
        } else {
          pinnedTip.style.left  = "auto";
          pinnedTip.style.right = "226px";
          pinnedTip.style.top   = "90px";
        }
        pinnedTip.style.display = "block";
      }
    } else {
      pinnedTip.style.display = "none";
    }
  }

  // ── clear trail series ─────────────────────────────────────────────────
  function clearTrails() {
    var seriesUpdate = [];
    for (var g = 0; g < nGroups; g++) {
      seriesUpdate[trailLineIdx(g)]  = { data: [] };
      seriesUpdate[trailGhostIdx(g)] = { data: [] };
    }
    chart.setOption({ series: seriesUpdate }, false);
  }

  // ── apply new font size ────────────────────────────────────────────────
  function applyLabelSize(sz) {
    labelFontSize         = Math.max(6, Math.min(24, sz));
    fsReadout.textContent = String(labelFontSize);
    renderFrame(startProg);
  }

  // ── animation state ────────────────────────────────────────────────────
  var playing   = false;
  var startWall = null;
  var startProg = 0;
  var rafId     = null;

  function animStep(ts) {
    if (!startWall) startWall = ts;
    var elapsed = ts - startWall;
    var prog    = startProg + elapsed / duration;
    if (prog >= 1) {
      renderFrame(1);
      rafId = null;
      setTimeout(function() {
        if (playing) {
          startProg = 0;
          startWall = null;
          rafId = requestAnimationFrame(animStep);
        }
      }, 2000);
      return;
    }
    renderFrame(prog);
    rafId = requestAnimationFrame(animStep);
  }

  function play() {
    playing = true; startWall = null;
    playBtn.innerHTML = PAUSE_HTML;
    rafId = requestAnimationFrame(animStep);
  }

  function pause() {
    playing = false;
    if (rafId) { cancelAnimationFrame(rafId); rafId = null; }
    startProg = parseFloat(slider.value) / 10000;
    startWall = null;
    playBtn.innerHTML = PLAY_HTML;
  }

  // ── events ─────────────────────────────────────────────────────────────
  playBtn.addEventListener("click",    function() { playing ? pause() : play(); });
  slider.addEventListener("mousedown", function() { if (playing) pause(); });
  slider.addEventListener("input",     function() {
    startProg = parseFloat(slider.value) / 10000;
    renderFrame(startProg);
  });
  btnSmaller.addEventListener("click", function() { applyLabelSize(labelFontSize - 1); });
  btnLarger.addEventListener("click",  function() { applyLabelSize(labelFontSize + 1); });
  trailsBtn.addEventListener("click",  function() {
    showTrails = !showTrails;
    updateTrailsBtn();
    if (!showTrails) clearTrails();
    else renderFrame(parseFloat(slider.value) / 10000);
  });

  // (legendselectchanged no longer needed — Color panel manages legendSelected directly)

  // Click on a bubble — show trails only for that entity; click again to clear.
  // Guard against clicks on trail series (their names start with ".trail_").
  chart.on("click", function(params) {
    if (params.componentType !== "series") return;
    if (params.seriesName && params.seriesName.indexOf(".trail_") === 0) return;
    if (highlightedName === params.name) {
      highlightedName = null;
    } else {
      highlightedName = params.name;
    }
    renderFrame(parseFloat(slider.value) / 10000);
  });

  // Click on empty chart area — restore all trails
  chart.getZr().on("click", function(e) {
    if (!e.target) {
      highlightedName = null;
      renderFrame(parseFloat(slider.value) / 10000);
    }
  });

  // Hover over a bubble — hide trails of all other entities while hovered.
  // mouseover/mouseout are more reliable than highlight/downplay for getting
  // the hovered entity name across all echarts4r/ECharts version combinations.
  chart.on("mouseover", function(params) {
    if (params.componentType !== "series") return;
    if (params.seriesName && params.seriesName.indexOf(".trail_") === 0) return;
    hoverName  = params.name;
    hoverGroup = entityGroupMap[params.name] || null;
    renderFrame(parseFloat(slider.value) / 10000);
  });

  chart.on("mouseout", function(params) {
    if (params.componentType !== "series") return;
    // Only clear hover if no click is locked — otherwise keep pinnedTip showing
    if (highlightedName === null) {
      hoverName  = null;
      hoverGroup = null;
      pinnedTip.style.display = "none";
    }
    renderFrame(parseFloat(slider.value) / 10000);
  });

  // ── initial render ─────────────────────────────────────────────────────
  renderFrame(0);
}
'

  # Inject R values by simple string replacement — no sprintf % parsing risk
  anim_js <- js_template
  anim_js <- gsub("__ENTITIES__",     jsonlite::toJSON(entity_list,  auto_unbox = TRUE, digits = 6), anim_js, fixed = TRUE)
  anim_js <- gsub("__TIMESTEPS__",    jsonlite::toJSON(time_steps,   auto_unbox = TRUE),             anim_js, fixed = TRUE)
  anim_js <- gsub("__GROUPS__",       jsonlite::toJSON(groups,       auto_unbox = FALSE),            anim_js, fixed = TRUE)
  anim_js <- gsub("__GROUPCOLORS__",  jsonlite::toJSON(unname(group_colors), auto_unbox = FALSE),    anim_js, fixed = TRUE)
  anim_js <- gsub("__DURATION__",     as.character(as.integer(duration)),                            anim_js, fixed = TRUE)
  anim_js <- gsub("__TIMENAME__",     time_label,                                                    anim_js, fixed = TRUE)
  anim_js <- gsub("__LABELSIZE__",    as.character(init_label_size),                                 anim_js, fixed = TRUE)
  anim_js <- gsub("__LABELCOLOUR__",  tolower(as.character(isTRUE(label_colour))),                   anim_js, fixed = TRUE)
  anim_js <- gsub("__XLABEL__",       x_label,                                                       anim_js, fixed = TRUE)
  anim_js <- gsub("__YLABEL__",       y_label,                                                       anim_js, fixed = TRUE)
  anim_js <- gsub("__XDECIMALS__",    as.character(x_decimals),                                      anim_js, fixed = TRUE)
  anim_js <- gsub("__YDECIMALS__",    as.character(y_decimals),                                      anim_js, fixed = TRUE)
  anim_js <- gsub("__TRAILS__",       tolower(as.character(isTRUE(trails))),                         anim_js, fixed = TRUE)
  anim_js <- gsub("__TRAILLENGTH__",  as.character(as.integer(trail_length)),                        anim_js, fixed = TRUE)
  anim_js <- gsub("__HOVERFOCUS__",   paste0('"', hover_focus, '"'),                                 anim_js, fixed = TRUE)
  anim_js <- gsub("__TOOLTIPFOLLOW__", tolower(as.character(isTRUE(tooltip_follow))),                anim_js, fixed = TRUE)


  widget <- htmlwidgets::onRender(widget, anim_js)
  widget
}


# ── quick demo (uncomment to run) ─────────────────────────────────────────────

# gap <- load_gapminder()
#
# motionChart(gap,
#             id           = "country",
#             time         = "year",
#             x            = "gdpPercap",
#             y            = "lifeExp",
#             size         = "pop",
#             color        = "continent",
#             x_log        = TRUE,
#             duration     = 17000,
#             trails       = TRUE,
#             trail_length = 4,
#             hover_focus  = "group",   # "group" or "entity"
#             label_colour = TRUE,
#             title        = "Gapminder — Health & Wealth of Nations")
