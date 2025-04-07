require "spec_helper"
require "data_style_sanitizer"

RSpec.describe DataStyleSanitizer::Processor do
  let(:nonce) { "testnonce123" }

  def process_html(input)
    DataStyleSanitizer::Processor.new(input, nonce: nonce).process
  end

  it "returns the original HTML if there are no data-style attributes" do
    input = "<div class='foo'>Hello</div>"
    output = process_html(input)

    expect(output).to include("<div class=\"foo\">Hello</div>")
    expect(output).not_to include("<style")
  end

  it "replaces data-style with generated class and injects style tag with nonce" do
    input = "<div data-style=\"color: red;\">Hello</div>"
    output = process_html(input)

    expect(output).to match(/<div class=\"ds-[a-f0-9]+\">Hello<\/div>/)
    expect(output).to match(%r{<style nonce="#{nonce}">})
    expect(output).to match(/\.ds-[a-f0-9]+ { color: red !important; }/)
  end

  it "preserves existing classes when adding new ones" do
    input = '<span class="existing" data-style="font-weight: bold;">Text</span>'
    output = process_html(input)

    expect(output).to match(/<span class=\"existing ds-[a-f0-9]+\">Text<\/span>/)
    expect(output).to match(/\.ds-[a-f0-9]+ { font-weight: bold !important; }/)
  end

  it "removes data-style after applying transformation" do
    input = '<p data-style="margin: 10px;">Para</p>'
    output = process_html(input)

    expect(output).not_to include("data-style=")
    expect(output).to include("margin: 10px !important;")
  end

  it "consolidates repeated data-style strings under one class" do
    input = <<~HTML
      <div data-style="color: blue;">One</div>
      <div data-style="color: blue;">Two</div>
    HTML

    output = process_html(input)

    class_names = output.scan(/class=\"(ds-[a-f0-9]+)\"/).flatten
    expect(class_names.uniq.length).to eq(1)
    expect(output.scan(/<style nonce=/).count).to eq(1)
    expect(output).to include("color: blue !important;")
  end

  it "handles multiple unique styles in a single response" do
    input = <<~HTML
      <div data-style="color: green;">Green</div>
      <div data-style="font-size: 14px;">Size</div>
    HTML

    output = process_html(input)

    expect(output).to include("color: green !important;")
    expect(output).to include("font-size: 14px !important;")
    expect(output.scan(/<style nonce=/).count).to eq(1)
  end

  it "ignores malformed data-style values gracefully" do
    input = "<div data-style=\";:bad-css;;\">Oops</div>"
    output = process_html(input)

    expect(output).to match(/<div class=\"ds-[a-f0-9]+\">Oops<\/div>/)
    expect(output).to include("!important;")
  end
end
