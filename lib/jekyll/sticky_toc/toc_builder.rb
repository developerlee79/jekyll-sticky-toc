# frozen_string_literal: true

require_relative "root_style_builder"

module Jekyll
  module StickyToc
    class TocBuilder
      TEMPLATE_PATH = File.expand_path("templates/toc.html", __dir__)

      def initialize(config:)
        @config = config
      end

      def build(headings)
        normalized_headings = normalize_heading_ids(headings)
        normalized_headings = collapse_duplicate_headings(normalized_headings)
        return nil if normalized_headings.size <= 1

        toc_items_html = TocListRenderer.new(@config).render(normalized_headings)
        template = Liquid::Template.parse(File.read(TEMPLATE_PATH))
        scroll_attrs = RootStyleBuilder.scroll_data_attributes(@config)
        template.render!(liquid_locals(toc_items_html, scroll_attrs))
      end

      private

      def liquid_locals(toc_items_html, scroll_attrs)
        {
          "side" => @config["side"],
          "fold" => @config["fold"],
          "marker" => @config["marker"],
          "jtoc_hide_at_bottom" => scroll_attrs["jtoc_hide_at_bottom"],
          "jtoc_hide_at_top" => scroll_attrs["jtoc_hide_at_top"],
          "toc_items_html" => toc_items_html
        }
      end

      def normalize_heading_ids(headings)
        seen = Hash.new(0)
        headings.map do |heading|
          base_id = heading["id"].to_s.strip
          base_id = slugify(heading["text"]) if base_id.empty?
          count = seen[base_id]
          resolved_id = count.zero? ? base_id : "#{base_id}-#{count}"
          seen[base_id] += 1
          heading.merge("id" => resolved_id)
        end
      end

      def slugify(text)
        raw = text.to_s.downcase.strip
        slug = raw.gsub(/[^[:alnum:]\p{Han}\p{Hangul}\p{Hiragana}\p{Katakana}\s\-_]/u, "")
                  .gsub(/[\s_]+/, "-")
                  .gsub(/-+/, "-")
                  .gsub(/^-|-$/, "")
        slug.empty? ? "section" : slug
      end

      def collapse_duplicate_headings(headings)
        deduped = []
        headings.each do |heading|
          next if deduped.last && same_heading?(deduped.last, heading)

          deduped << heading
        end
        deduped
      end

      def same_heading?(left, right)
        left["level"].to_i == right["level"].to_i &&
          left["id"].to_s == right["id"].to_s &&
          left["text"].to_s == right["text"].to_s
      end
    end
  end
end
