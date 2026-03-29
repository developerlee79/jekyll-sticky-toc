# Jekyll Sticky TOC

![Screenshots](/images/screenshots.png)

[![Gem Version](https://badge.fury.io/rb/jekyll-sticky-toc.svg)](https://badge.fury.io/rb/jekyll-sticky-toc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Jekyll Sticky TOC** is a lightweight, open-source [Jekyll](https://jekyllrb.com) plugin that automatically generates a sticky table of contents from your page headings.

It works flawlessly across mobile and desktop out-of-the-box, with flexible styling options available through simple configuration.

<br>

* [Installation](#installation)
* [Getting Started](#getting-started)
* [Configuration](#configuration)
* [Contributions](#contributions)

<br>

## Installation

### With Bundler

Add `jekyll-sticky-toc` gem to your `Gemfile`:

```ruby
gem "jekyll-sticky-toc"
```

or use GitHub repository link:

```ruby
gem "jekyll-sticky-toc", git: "https://github.com/developerlee79/jekyll-sticky-toc.git"
```

### Manual

Or install the gem manually and specify the plugin in your `_config.yml`:

```shell
gem install jekyll-sticky-toc
```

```yaml
plugins:
  - jekyll-sticky-toc
```

<br>

## Getting Started

Add `toc: true` to a page where you want TOC to appear:

```markdown
---
layout: default
title: My Project
toc: true
---
```

To enable TOC for collections by default, see the `target_collection` option in the Configuration section.

Build and run your site:

```bash
bundle exec jekyll serve
```

<br>

## Configuration

Add or adjust these options in `_config.yml`:

```yaml
sticky_toc:
  min_depth: 1
  max_depth: 6
  target_collection: []
  side: right
  fold: false
  marker: none
  scroll_behavior:
    hide_at_top: false
    hide_at_bottom: true
  style:
    background_color: "#ffffff"
    text_color: "#111827"
    highlight_color: "#2563eb"
    border_style:
      type: solid
      color: "#e5e7eb"
      radius: 8
    width: 15
    height: 50
    vertical_start: 30
```

| Key | Default | Description |
|-------------------------------|-----------|-------------|
| `min_depth` | `1` | Minimum heading depth included (`1` = `h1`) |
| `max_depth` | `6` | Maximum heading depth included |
| `target_collection` | `[]` | List of collections to enable TOC by default. Individual `toc: false` in Front Matter will override this. |
| `side` | `right` | TOC panel side (`left` or `right`) |
| `fold` | `false` | Enables collapsible nested sections |
| `marker` | `none` | Marker style when `fold` is `false` (`dash`, `dot`, `none`) |
| `scroll_behavior.hide_at_top` | `false` | Hides TOC at page top when enabled (No effect in mobile layout) |
| `scroll_behavior.hide_at_bottom` | `true` | Hides TOC at page bottom when enabled (No effect in mobile layout) |
| `style.background_color` | `#ffffff` | Panel base background color |
| `style.text_color` | `#111827` | Panel text color |
| `style.highlight_color` | `#2563eb` | Active and hover highlight color |
| `style.border_style.type` | `solid` | Border type (`solid`, `dot`, `none`) |
| `style.border_style.color` | `#e5e7eb` | Border color |
| `style.border_style.radius` | `8` | Border radius in px |
| `style.width` | `15` | Desktop: % of `100vw`, then CSS clamps 160–640px. Mobile layout uses fixed sizing. Allowed `8`-`40`. |
| `style.height` | `50` | Desktop: % of `(100vh − 120px)` for panel `max-height`. Mobile uses separate rules. Allowed `20`–`90`. |
| `style.vertical_start` | `30` | Desktop: panel `top` as % of `100vh`. At ≤900px, CSS uses `top: auto` and bottom anchoring instead. Allowed `0`–`100`. |

<br>

### Theming and CSS variables

The TOC panel reads appearance from CSS custom properties on `.jtoc-root`, which inherit from ancestor elements.

You can match multiple themes(e.light / dark) by scoping those variables under selectors such as `html[data-theme="…"]`, classes on `html` or `body`, or `prefers-color-scheme`, so the panel follows your site chrome without another Jekyll build.

Precedence is as follows:

| Priority | Source |
|---------:|--------|
| 1 | Site CSS on `.jtoc-root` or an ancestor (for example `--jtoc-bg`) |
| 2 | `_config.yml` under `sticky_toc.style` |
| 3 | Bundled plugin defaults |

For each property, if your CSS sets a value that differs from the plugin default, that CSS wins. Otherwise the config value applies when present; otherwise the bundled default is used.

Set the variables on `.jtoc-root` or any ancestor. Example with theme-scoped selectors:

```css
html[data-theme="light"] .jtoc-root {
  --jtoc-bg: #ffffff;
  --jtoc-text: #111827;
  --jtoc-highlight: #2563eb;
  --jtoc-border-color: #e5e7eb;
}

html[data-theme="dark"] .jtoc-root {
  --jtoc-bg: #111827;
  --jtoc-text: #f3f4f6;
  --jtoc-highlight: #60a5fa;
  --jtoc-border-color: #374151;
}
```

| Variable | Role | Plugin default |
|----------|------|----------------|
| `--jtoc-bg` | Base background for panel tint | `#ffffff` |
| `--jtoc-text` | Root text color | `#111827` |
| `--jtoc-muted` | TOC link default color | `#6b7280` |
| `--jtoc-highlight` | Active and hover accent | `#2563eb` |
| `--jtoc-highlight-bg-hover` | Row hover background | Derived from highlight |
| `--jtoc-highlight-bg-active` | Active row background | Derived from highlight |
| `--jtoc-border-color` | Panel border color | `#e5e7eb` |
| `--jtoc-border-style` | Border style | `solid` |
| `--jtoc-radius` | Panel corner radius in px | `8px` |
| `--jtoc-width-ratio` | Same as `style.width`: % of `100vw`, 160–640px clamp (desktop; mobile overrides) | `15` |
| `--jtoc-height-ratio` | Same as `style.height`: % of `(100vh − 120px)` for `max-height` base (desktop; mobile overrides) | `50` |
| `--jtoc-panel-vertical-start` | Same as `style.vertical_start`: % of `100vh` for `top` (desktop; overridden ≤900px) | `30` |
| `--jtoc-scroll-margin-top` | Heading anchor scroll margin | `88px` |

<br>

## Contributions

Contributions are welcome. If you have an improvement or idea, feel free to open a pull request.
