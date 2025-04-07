# frozen_string_literal: true

require "data_style_sanitizer/processor"
require "data_style_sanitizer/railtie" if defined?(Rails)
require_relative "data_style_sanitizer/version"

module DataStyleSanitizer
  class Error < StandardError; end

  class << self
    def process(html, nonce:)
      Processor.new(html, nonce: nonce).process
    end
  end
end
