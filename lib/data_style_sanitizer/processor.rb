require "nokogiri"
require "securerandom"
require "digest"

module DataStyleSanitizer
  class Processor
    def initialize(html, nonce:)
      @doc = Nokogiri::HTML::DocumentFragment.parse(html)
      @nonce = nonce
      @styles = {}
    end

    def process
      extract_styles
      inject_style_block
      @doc.to_html
    end

    private

    def extract_styles
      @doc.css('[data-style]').each_with_index do |node, i|
        style_string = node.get_attribute('data-style')
        class_name = generate_class_name(style_string)

        # Apply class and remove attribute
        node.remove_attribute('data-style')
        node.set_attribute('class', [node.get_attribute('class'), class_name].compact.join(' '))

        # Store unique styles
        @styles[class_name] ||= style_string
      end
    end

    def generate_class_name(style_string)
      hash = Digest::SHA256.hexdigest(style_string)[0..7]
      "ds-#{hash}"
    end

    def inject_style_block
      return if @styles.empty?
    
      # Create the <style> tag
      style_tag = Nokogiri::XML::Node.new("style", @doc)
      style_tag["nonce"] = @nonce
    
      # Generate CSS rules
      css_rules = @styles.map do |class_name, rule|
        rule_lines = rule.split(';').map(&:strip).reject(&:empty?)
        rule_lines.map! { |line| "#{line.strip} !important;" } # Ensure override
        ".#{class_name} { #{rule_lines.join(' ')} }"
      end.join("\n")
    
      style_tag.content = css_rules
    
      # Add the <style> tag to the <head> if it exists, otherwise to the root
      head = @doc.at_css("head")
      if head
        head.add_child(style_tag)
      else
        @doc.add_child(style_tag)
      end
    end
  end
end
