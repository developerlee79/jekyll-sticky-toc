# frozen_string_literal: true

module Jekyll
  module StickyToc
    module HeadingSync
      extend self

      def merge(rendered_headings, source_signatures)
        return [] if source_signatures.empty?

        rendered_index = 0
        source_signatures.map do |source_level, source_text|
          matched_heading = nil
          while rendered_index < rendered_headings.length
            candidate = rendered_headings[rendered_index]
            rendered_index += 1
            next unless heading_matches?(candidate, source_level, source_text)

            matched_heading = candidate
            break
          end

          {
            "level" => source_level,
            "text" => source_text,
            "id" => matched_heading&.dig("id")
          }
        end
      end

      private

      def heading_matches?(candidate, source_level, source_text)
        candidate["level"].to_i == source_level &&
          candidate["text"].to_s.strip == source_text
      end
    end
  end
end
