# frozen_string_literal: true

module Jekyll
  module StickyToc
    class Config
      MAX_DEPTH = 6

      DEFAULTS = {
        "min_depth" => 1,
        "max_depth" => MAX_DEPTH,
        "target_collection" => [],
        "side" => "right",
        "fold" => false,
        "marker" => "none",
        "scroll_behavior" => {
          "hide_at_bottom" => true,
          "hide_at_top" => false
        },
        "style" => {
          "background_color" => "#ffffff",
          "text_color" => "#111827",
          "highlight_color" => "#2563eb",
          "border_style" => {
            "type" => "solid",
            "color" => "#e5e7eb",
            "radius" => 8
          },
          "width" => 15,
          "height" => 50,
          "vertical_start" => 30
        }
      }.freeze

      VALID_SIDES = %w[left right].freeze
      VALID_MARKER_TYPES = %w[dash dot none].freeze
      VALID_BORDER_TYPES = %w[solid dot none].freeze
      STYLE_COLOR_KEYS = %w[background_color text_color highlight_color].freeze

      def self.resolve(site_config)
        raw_toc = site_config.fetch("sticky_toc", {})
        raw_toc = {} unless raw_toc.is_a?(Hash)
        toc_config = deep_merge(DEFAULTS, raw_toc)
        apply_resolved_fields!(toc_config, raw_toc)
        strip_ignored_top_level_keys!(toc_config)
        toc_config["style"] = normalize_style(toc_config["style"], raw_toc)
        toc_config
      end

      def self.apply_resolved_fields!(toc_config, raw_toc)
        toc_config["max_depth"] = normalize_max_depth(toc_config["max_depth"])
        toc_config["min_depth"] = normalize_min_depth(toc_config["min_depth"], toc_config["max_depth"])
        toc_config["target_collection"] = normalize_target_collection(toc_config["target_collection"])
        toc_config["side"] = normalize_side(toc_config["side"])
        toc_config["fold"] = normalize_fold(toc_config, raw_toc)
        toc_config["marker"] = normalize_marker_setting(toc_config, raw_toc)
        toc_config["scroll_behavior"] = normalize_scroll_behavior(toc_config)
      end
      private_class_method :apply_resolved_fields!

      def self.strip_ignored_top_level_keys!(toc_config)
        toc_config.delete("top_expand")
        toc_config.delete("hide_at_bottom")
        toc_config.delete("hide_at_top")
      end
      private_class_method :strip_ignored_top_level_keys!

      def self.deep_merge(base, override)
        return base unless override.is_a?(Hash)

        base.each_with_object({}) do |(key, base_value), acc|
          override_value = override[key]
          acc[key] =
            if base_value.is_a?(Hash)
              deep_merge(base_value, override_value)
            elsif override.key?(key)
              override_value
            else
              base_value
            end
        end
      end
      private_class_method :deep_merge

      def self.style_slices(toc_config, raw_toc)
        style_hash = toc_config["style"].is_a?(Hash) ? toc_config["style"] : {}
        raw_style = raw_toc["style"].is_a?(Hash) ? raw_toc["style"] : {}
        [style_hash, raw_style]
      end
      private_class_method :style_slices

      def self.preference_from_raw_then_style(toc_config, raw_toc, key)
        style_hash, raw_style = style_slices(toc_config, raw_toc)
        return raw_toc[key] if raw_toc.key?(key)
        return raw_style[key] if raw_style.key?(key)

        style_hash[key]
      end
      private_class_method :preference_from_raw_then_style

      def self.style_preferred_scalar(raw_style, style_hash, key)
        raw_style.key?(key) ? raw_style[key] : style_hash[key]
      end
      private_class_method :style_preferred_scalar

      def self.nested_style_map(parent, key)
        child = parent[key]
        child.is_a?(Hash) ? child : {}
      end
      private_class_method :nested_style_map

      def self.normalize_max_depth(value)
        parsed = value.to_i
        return DEFAULTS["max_depth"] if parsed.zero?

        parsed.clamp(1, MAX_DEPTH)
      end
      private_class_method :normalize_max_depth

      def self.normalize_min_depth(value, max_depth)
        parsed = value.to_i
        parsed = DEFAULTS["min_depth"] if parsed.zero?

        parsed.clamp(1, MAX_DEPTH).clamp(1, max_depth)
      end
      private_class_method :normalize_min_depth

      def self.normalize_target_collection(value)
        return [] unless value.is_a?(Array)

        value.map(&:to_s).reject(&:empty?).uniq
      end
      private_class_method :normalize_target_collection

      def self.normalize_side(value)
        side = value.to_s
        VALID_SIDES.include?(side) ? side : DEFAULTS["side"]
      end
      private_class_method :normalize_side

      def self.normalize_style(value, raw_toc)
        style_hash = value.is_a?(Hash) ? value : {}
        _, raw_style = style_slices({ "style" => style_hash }, raw_toc)
        border_raw = nested_style_map(raw_style, "border_style")
        border_merged = nested_style_map(style_hash, "border_style")
        defaults_style = DEFAULTS["style"]

        normalize_style_color_fields(raw_style, style_hash, defaults_style).merge(
          "border_style" => normalize_style_border_block(border_raw, border_merged, defaults_style["border_style"]),
          "width" => normalize_integer(
            style_preferred_scalar(raw_style, style_hash, "width"),
            defaults_style["width"],
            min: 8,
            max: 40
          ),
          "height" => normalize_integer(
            style_preferred_scalar(raw_style, style_hash, "height"),
            defaults_style["height"],
            min: 20,
            max: 90
          ),
          "vertical_start" => normalize_integer(
            style_preferred_scalar(raw_style, style_hash, "vertical_start"),
            defaults_style["vertical_start"],
            min: 0,
            max: 100
          )
        )
      end
      private_class_method :normalize_style

      def self.normalize_style_color_fields(raw_style, style_hash, defaults_style)
        STYLE_COLOR_KEYS.to_h do |key|
          [
            key,
            normalize_hex_color(
              style_preferred_scalar(raw_style, style_hash, key),
              defaults_style[key]
            )
          ]
        end
      end
      private_class_method :normalize_style_color_fields

      def self.normalize_style_border_block(border_raw, border_merged, border_defaults)
        {
          "type" => normalize_border_type(style_preferred_scalar(border_raw, border_merged, "type")),
          "color" => normalize_hex_color(
            style_preferred_scalar(border_raw, border_merged, "color"),
            border_defaults["color"]
          ),
          "radius" => normalize_non_negative_integer(
            style_preferred_scalar(border_raw, border_merged, "radius"),
            border_defaults["radius"]
          )
        }
      end
      private_class_method :normalize_style_border_block

      def self.normalize_fold(toc_config, raw_toc)
        fold_value = preference_from_raw_then_style(toc_config, raw_toc, "fold")
        normalize_boolean(fold_value, DEFAULTS["fold"])
      end
      private_class_method :normalize_fold

      def self.normalize_marker_setting(toc_config, raw_toc)
        marker_value = preference_from_raw_then_style(toc_config, raw_toc, "marker")
        normalize_marker(marker_value)
      end
      private_class_method :normalize_marker_setting

      def self.normalize_scroll_behavior(toc_config)
        defaults_scroll = DEFAULTS["scroll_behavior"]
        merged_scroll = toc_config["scroll_behavior"]
        merged_scroll = {} unless merged_scroll.is_a?(Hash)

        {
          "hide_at_bottom" => normalize_boolean(
            merged_scroll["hide_at_bottom"],
            defaults_scroll["hide_at_bottom"]
          ),
          "hide_at_top" => normalize_boolean(
            merged_scroll["hide_at_top"],
            defaults_scroll["hide_at_top"]
          )
        }
      end
      private_class_method :normalize_scroll_behavior

      def self.normalize_marker(value)
        marker = value.to_s
        return marker if VALID_MARKER_TYPES.include?(marker)

        DEFAULTS["marker"]
      end
      private_class_method :normalize_marker

      def self.normalize_hex_color(value, default)
        raw = value.to_s.strip
        return default unless raw.match?(/\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/)

        if raw.length == 4
          "##{raw[1] * 2}#{raw[2] * 2}#{raw[3] * 2}".downcase
        else
          raw.downcase
        end
      end
      private_class_method :normalize_hex_color

      def self.normalize_border_type(value)
        border_type = value.to_s
        return border_type if VALID_BORDER_TYPES.include?(border_type)

        DEFAULTS["style"]["border_style"]["type"]
      end
      private_class_method :normalize_border_type

      def self.normalize_boolean(value, default)
        return true if value == true
        return false if value == false
        return true if value.is_a?(String) && value.match?(/\A(true|1|yes|on)\z/i)
        return false if value.is_a?(String) && value.match?(/\A(false|0|no|off)\z/i)

        default
      end
      private_class_method :normalize_boolean

      def self.normalize_integer(value, default, min:, max:)
        parsed = value.to_i
        parsed = default if parsed.zero? && value.to_s != "0"
        parsed.clamp(min, max)
      end
      private_class_method :normalize_integer

      def self.normalize_non_negative_integer(value, default)
        parsed = value.to_i
        parsed = default if parsed.zero? && value.to_s != "0"
        [parsed, 0].max
      end
      private_class_method :normalize_non_negative_integer
    end
  end
end
