# frozen_string_literal: true

module Jekyll
  module StickyToc
    class RootStyleBuilder
      def self.scroll_data_attributes(config)
        scroll = config["scroll_behavior"].is_a?(Hash) ? config["scroll_behavior"] : {}
        {
          "jtoc_hide_at_bottom" => html_bool(scroll.fetch("hide_at_bottom", true)),
          "jtoc_hide_at_top" => html_bool(scroll.fetch("hide_at_top", false))
        }
      end

      def self.html_bool(value)
        value ? "true" : "false"
      end
      private_class_method :html_bool
    end
  end
end
