# frozen_string_literal: true

require "data_style_sanitizer"

RSpec.describe DataStyleSanitizer do
  let(:html_input) do
    <<~HTML
      <html>
        <head><meta name="csp-nonce" content="abc123"></head>
        <body>
          <div data-style="color: red; font-weight: bold;"></div>
          <span data-style="color: red; font-weight: bold;"></span>
          <p data-style="color: blue;"></p>
        </body>
      </html>
    HTML
  end

  let(:output) { described_class.process(html_input, nonce: "abc123") }
  let(:doc) { Nokogiri::HTML(output) }

  it "injects only unique styles into the style tag" do
    style_tag = doc.at_css("style[nonce='abc123']")
    expect(style_tag).not_to be_nil
  
    css_text = style_tag.text
    expect(css_text.scan(/\.(ds-[a-f0-9]+) \{/).flatten.uniq.count).to eq(2)
    expect(css_text).to include("color: red")
    expect(css_text).to include("color: blue")
  end

  it "applies the same class to elements with the same data-style" do
    div_class = doc.at_css("div")["class"]
    span_class = doc.at_css("span")["class"]
    expect(div_class).to eq(span_class)
  end

  it "assigns a different class for different data-style" do
    div_class = doc.at_css("div")["class"]
    p_class = doc.at_css("p")["class"]
    expect(p_class).not_to eq(div_class)
  end

  it "removes the data-style attributes" do
    expect(doc.css("[data-style]")).to be_empty
  end
end
