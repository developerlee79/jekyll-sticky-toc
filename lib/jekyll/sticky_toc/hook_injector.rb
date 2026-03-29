# frozen_string_literal: true

require "json"

module Jekyll
  module StickyToc
    class HookInjector
      CSS_PATH = File.expand_path("../../../assets/jekyll-sticky-toc.css", __dir__)
      JS_PATH = File.expand_path("../../../assets/jekyll-sticky-toc.js", __dir__)

      def self.register
        register_for(:documents)
        register_for(:pages)
      end

      def self.register_for(target)
        Jekyll::Hooks.register target, :post_render do |document|
          process(document)
        end
      end
      private_class_method :register_for

      def self.process(document)
        return unless html_document?(document)
        return if document.output.to_s.include?("data-jtoc-root")

        config = Config.resolve(document.site.config)
        return unless eligible?(document, config)

        depth = depth_range(config)
        rendered_headings = HeadingExtractor.new(**depth).extract(document.output)
        source_signatures = SourceHeadingExtractor.new(document, **depth).signatures
        headings = HeadingSync.merge(rendered_headings, source_signatures)
        toc_html = TocBuilder.new(config: config).build(headings)
        return if toc_html.nil?

        payload = build_payload(config, toc_html)
        document.output = inject(document.output, payload)
      end
      private_class_method :process

      def self.html_document?(document)
        document.respond_to?(:output_ext) && document.output_ext == ".html" && !document.output.to_s.empty?
      end
      private_class_method :html_document?

      def self.eligible?(document, config)
        toc = document.data["toc"]
        return false if toc == false

        return true if toc == true

        collection = document_collection_label(document)
        config["target_collection"].include?(collection)
      end
      private_class_method :eligible?

      def self.document_collection_label(document)
        return document.collection.label.to_s if document.respond_to?(:collection) && document.collection

        document.data.fetch("collection", "").to_s
      end
      private_class_method :document_collection_label

      def self.build_payload(config, toc_html)
        css = File.read(CSS_PATH)
        js = File.read(JS_PATH)
        <<~HTML
          <style data-jtoc-style>#{css}</style>
          #{toc_html}
          <script data-jtoc-config type="application/json">#{JSON.generate(runtime_config_for(config))}</script>
          <script data-jtoc-script>#{js}</script>
        HTML
      end
      private_class_method :build_payload

      def self.depth_range(config)
        {
          min_depth: config["min_depth"],
          max_depth: config["max_depth"]
        }
      end
      private_class_method :depth_range

      def self.runtime_config_for(config)
        {
          "side" => config["side"],
          "fold" => config["fold"],
          "background_color" => config.dig("style", "background_color"),
          "text_color" => config.dig("style", "text_color"),
          "highlight_color" => config.dig("style", "highlight_color"),
          "border_style" => config.dig("style", "border_style"),
          "marker" => config["marker"],
          "scroll_behavior" => config["scroll_behavior"],
          "width" => config.dig("style", "width"),
          "height" => config.dig("style", "height"),
          "vertical_start" => config.dig("style", "vertical_start")
        }
      end
      private_class_method :runtime_config_for

      def self.inject(output, payload)
        with_body = output.sub(/<body[^>]*>/i) { |match| "#{match}\n#{payload}" }
        return with_body unless with_body == output

        "#{payload}\n#{output}"
      end
      private_class_method :inject
    end
  end
end

Jekyll::StickyToc::HookInjector.register
