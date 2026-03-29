# frozen_string_literal: true

require "erb"

module Jekyll
  module StickyToc
    class TocListRenderer
      Row = Struct.new(
        :item_class,
        :actual_level,
        :display_level,
        :text,
        :id,
        :has_children,
        :fold_enabled,
        :open_display_level,
        :marker
      ) do
        def fold_open?
          fold_enabled && !open_display_level.nil? && display_level == open_display_level
        end
      end

      AppendFrame = Struct.new(
        :result,
        :heading,
        :index,
        :headings,
        :base_level,
        :fold_enabled,
        :marker,
        :open_display_level,
        :current_level
      )

      def initialize(config)
        @config = config
      end

      def render(headings)
        result = +""
        base_level = minimum_heading_level(headings)
        fold_enabled = @config["fold"]
        marker = @config["marker"]
        open_display_level = fold_open_level(headings, base_level) if fold_enabled
        current_level = 0

        headings.each_with_index do |heading, index|
          frame = AppendFrame.new(
            result, heading, index, headings, base_level, fold_enabled, marker, open_display_level, current_level
          )
          current_level = append_heading(frame)
        end

        current_level.times { result << "</li></ul>" }
        result
      end

      private

      def minimum_heading_level(headings)
        headings.map { |h| h["level"].to_i }.min
      end

      def heading_followed_by_deeper?(headings, index, current_level)
        following = headings[index + 1]
        following && following["level"].to_i > current_level
      end

      def fold_open_level(headings, base_level)
        levels_with_children = headings.each_with_index.filter_map do |heading, index|
          actual_level = heading["level"].to_i
          next unless heading_followed_by_deeper?(headings, index, actual_level)

          actual_level - base_level
        end
        return nil if levels_with_children.empty?

        levels_with_children.min
      end

      def append_heading(frame)
        heading = frame.heading
        actual_level = heading["level"].to_i
        display_level = actual_level - frame.base_level
        nesting_level = display_level + 1
        text = ERB::Util.html_escape(heading["text"])
        id = ERB::Util.html_escape(heading["id"])
        has_children = heading_followed_by_deeper?(frame.headings, frame.index, actual_level)

        adjust_list_depth(frame.result, frame.current_level, nesting_level)
        row = Row.new(
          item_classes(display_level, frame.fold_enabled, has_children, frame.open_display_level),
          actual_level,
          display_level,
          text,
          id,
          has_children,
          frame.fold_enabled,
          frame.open_display_level,
          frame.marker
        )
        append_heading_row(frame.result, row)
        nesting_level
      end

      def adjust_list_depth(result, current_level, nesting_level)
        if nesting_level > current_level
          (nesting_level - current_level).times { result << '<ul class="jtoc-list">' }
        elsif nesting_level < current_level
          (current_level - nesting_level).times { result << "</li></ul>" }
          result << "</li>"
        else
          result << "</li>" unless current_level.zero?
        end
        nesting_level
      end

      def item_classes(display_level, fold_enabled, has_children, open_display_level)
        classes = +"jtoc-item"
        classes << " has-children" if has_children
        classes << " is-open" if fold_open_branch?(display_level, fold_enabled, has_children, open_display_level)
        classes
      end

      def fold_open_branch?(display_level, fold_enabled, has_children, open_display_level)
        fold_enabled && has_children && !open_display_level.nil? && display_level == open_display_level
      end

      def append_heading_row(result, row)
        result << %(<li class="#{row.item_class}" data-jtoc-level="#{row.actual_level}" ) <<
          %(data-jtoc-display-level="#{row.display_level}">)
        result << '<div class="jtoc-link-row">'
        if row.fold_enabled && row.has_children
          expanded = row.fold_open?
          aria_expanded = expanded ? "true" : "false"
          result << %(<button class="jtoc-fold-toggle" type="button" aria-label="Toggle subsection" ) <<
            %(aria-expanded="#{aria_expanded}"></button>)
        elsif row.fold_enabled
          result << '<span class="jtoc-fold-spacer" aria-hidden="true"></span>'
        elsif row.marker != "none"
          result << %(<span class="jtoc-marker jtoc-marker-#{row.marker}" aria-hidden="true"></span>)
        end
        result << %(<a class="jtoc-link" href="##{row.id}" data-jtoc-link="#{row.id}">#{row.text}</a>)
        result << "</div>"
      end
    end
  end
end
