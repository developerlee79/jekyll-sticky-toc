# frozen_string_literal: true

require "cgi"
require "kramdown"

module Jekyll
  module StickyToc
    class SourceHeadingExtractor
      def initialize(document, min_depth:, max_depth:)
        @document = document
        @min_depth = min_depth
        @max_depth = max_depth
      end

      def signatures
        markdown = read_raw_markdown
        return [] if markdown.empty?

        root = Kramdown::Document.new(markdown).root
        collect_from_node(root, [])
      end

      private

      def read_raw_markdown
        path = @document.respond_to?(:path) ? @document.path.to_s : ""
        return strip_front_matter(File.read(path)) if !path.empty? && File.file?(path)

        @document.respond_to?(:content) ? @document.content.to_s : ""
      end

      def strip_front_matter(raw)
        text = raw.to_s
        lines = text.lines
        return text if lines.empty?
        return text unless lines.first.strip == "---"

        closing_index = nil
        lines[1..].each_with_index do |line, index|
          next unless line.strip == "---"

          closing_index = index + 1
          break
        end
        return text if closing_index.nil?

        lines[(closing_index + 1)..].join
      end

      def collect_from_node(node, result)
        if node.type == :header
          level = node.options.fetch(:level, 0).to_i
          text = normalize_heading_text(kramdown_plain_text(node))
          result << [level, text] if level.between?(@min_depth, @max_depth) && !text.empty?
        end

        node.children.each { |child| collect_from_node(child, result) }
        result
      end

      def kramdown_plain_text(node)
        return node.value.to_s if node.type == :text
        return "" if node.children.nil? || node.children.empty?

        node.children.map { |child| kramdown_plain_text(child) }.join(" ")
      end

      def normalize_heading_text(text)
        normalized = text.to_s.dup
        normalized.gsub!(/`([^`]*)`/, '\1')
        normalized.gsub!(/!\[([^\]]*)\]\([^)]+\)/, '\1')
        normalized.gsub!(/\[([^\]]+)\]\([^)]+\)/, '\1')
        normalized.gsub!(/[*_~]+/, "")
        normalized.gsub!(/<[^>]+>/, "")
        CGI.unescapeHTML(normalized).gsub(/\s+/, " ").strip
      end
    end
  end
end
