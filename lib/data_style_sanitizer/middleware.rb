# lib/data_style_sanitizer/middleware.rb
require 'nokogiri'
require 'digest'

class DataStyleSanitizer
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    if html_response?(headers)
      body = response.body.join
      doc = Nokogiri::HTML(body)
      style_map = {}

      doc.css('[data-style]').each do |el|
        style = el['data-style'].strip
        class_name = "ds-#{Digest::MD5.hexdigest(style)[0..6]}"
        el.remove_attribute('data-style')
        el['class'] = [el['class'], class_name].compact.join(' ')
        style_map[class_name] ||= style
      end

      if style_map.any?
        nonce = extract_nonce(doc)
        style_tag = Nokogiri::XML::Node.new('style', doc)
        style_tag['nonce'] = nonce if nonce
        style_tag.content = style_map.map { |klass, style| ".#{klass} { #{style} }" }.join("\n")
        doc.at('head') << style_tag
      end

      response = [doc.to_html]
    end

    [status, headers, response]
  end

  private

  def html_response?(headers)
    headers['Content-Type']&.include?('text/html')
  end

  def extract_nonce(doc)
    meta = doc.at('meta[name="csp-nonce"]')
    meta['content'] if meta
  end
end

