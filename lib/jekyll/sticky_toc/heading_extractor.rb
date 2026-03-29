# frozen_string_literal: true

require "cgi"

module Jekyll
  module StickyToc
    class HeadingExtractor
      HEADING_PATTERN = %r{<h([1-6])([^>]*)>(.*?)</h\1>}im.freeze
      ID_PATTERN = /id=(["'])(.*?)\1/i.freeze

      def initialize(min_depth:, max_depth:)
        @min_depth = min_depth
        @max_depth = max_depth
      end

      def extract(html)
        return [] if html.to_s.empty?

        headings = []
        html.to_s.scan(HEADING_PATTERN) do |level_str, attrs, inner_html|
          level = level_str.to_i
          next unless level.between?(@min_depth, @max_depth)

          text = normalize_text(inner_html)
          next if text.empty?

          headings << {
            "level" => level,
            "id" => extract_id(attrs),
            "text" => text
          }
        end
        headings
      end

      private

      def extract_id(attrs)
        match = attrs.to_s.match(ID_PATTERN)
        return nil unless match

        match[2].to_s
      end

      def normalize_text(inner_html)
        text = inner_html.to_s.gsub(/<[^>]+>/, "")
        CGI.unescapeHTML(text).gsub(/\s+/, " ").strip
      end
    end
  end
end
