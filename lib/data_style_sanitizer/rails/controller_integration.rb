# frozen_string_literal: true

module DataStyleSanitizer
  module Rails
    module ControllerIntegration
      extend ActiveSupport::Concern

      included do
        after_action :inject_data_style_sanitizer_styles
      end

      private

      def inject_data_style_sanitizer_styles
        return unless html_response? && response.body.include?('data-style')

        nonce = content_security_policy_nonce(:style) rescue nil
        style_block = DataStyleSanitizer::Renderer.generate_style_block(response.body, nonce: nonce)

        # Inject into <head>
        response.body.sub!('</head>', "#{style_block}</head>")
      end

      def html_response?
        response.content_type == 'text/html'
      end
    end
  end
end
