# frozen_string_literal: true

require_relative "data_style_sanitizer/processor"
require_relative "data_style_sanitizer/railtie"
require_relative "data_style_sanitizer/version"
require_relative "data_style_sanitizer/middleware"

module DataStyleSanitizer
  class Error < StandardError; end

  class << self
    def process(html, nonce:)
      Processor.new(html, nonce: nonce).process
    end
  end
end
