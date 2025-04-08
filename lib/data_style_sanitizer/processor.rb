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
      @doc.css("[data-style]").each do |node|
        style_string = node.get_attribute("data-style")
        next if style_string.nil? || style_string.strip.empty? # Skip empty attributes

        # Remove CSS comments and normalize spacing
        style_string = style_string.gsub(/\/\*.*?\*\//, "").strip
        style_string = style_string.split(";").map(&:strip).reject(&:empty?).join("; ")

        next if style_string.empty? # Skip if the style becomes empty after cleaning

        class_name = generate_class_name(style_string)

        # Apply class and remove attribute
        node.remove_attribute("data-style")
        node.set_attribute("class", [node.get_attribute("class"), class_name].compact.join(" "))

        # Store unique styles
        @styles[class_name] ||= style_string
      end
    end

    def generate_class_name(style_string)
      hash = Digest::SHA256.hexdigest(style_string.downcase)[0..7] # Ensure case-insensitivity
      "ds-#{hash}"
    end

    def inject_style_block
      return if @styles.empty?

      # Create the <style> tag
      style_tag = Nokogiri::XML::Node.new("style", @doc)
      style_tag["nonce"] = @nonce

      # Generate CSS rules
      css_rules = @styles.map do |class_name, rule|
        rule_lines = rule.split(";").map(&:strip).reject(&:empty?)
        rule_lines.map! { |line| "#{line.strip} !important;" } # Ensure override
        ".#{class_name} { #{rule_lines.join(" ")} }"
      end.join("\n")

      style_tag.content = css_rules

      # Add the <style> tag to the <head> if it exists, otherwise to the <body> or fragment
      head = @doc.at_css("head")
      if head
        head.add_child(style_tag)
      else
        body = @doc.at_css("body")
        if body
          body.add_child(style_tag)
        else
          @doc.add_child(style_tag) # Append directly to the fragment
        end
      end
    end
  end
end
