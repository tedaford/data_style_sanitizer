require "spec_helper"
require "rack"
require "data_style_sanitizer"

RSpec.describe DataStyleSanitizer::Middleware do
  let(:app) { ->(env) { [200, {"Content-Type" => "text/html"}, ["<html><head></head><body></body></html>"]] } }
  let(:middleware) { described_class.new(app) }

  describe "#extract_nonce" do
    let(:env) { {} }

    context "when nonce is in action_dispatch.content_security_policy_nonce" do
      before do
        env["action_dispatch.content_security_policy_nonce"] = {style: "testnonce123"}
      end

      it "extracts nonce from the correct place" do
        nonce = middleware.send(:extract_nonce, env)
        expect(nonce).to eq("testnonce123")
      end
    end

    context "when nonce is missing" do
      before do
        env["action_dispatch.content_security_policy_nonce"] = nil
        env["rack.session"] = nil
      end

      it "returns nil when nonce is not found" do
        nonce = middleware.send(:extract_nonce, env)
        expect(nonce).to be_nil
      end
    end

    context "when nonce in meta tag is malformed" do
      before do
        env["rack.session"] = {"meta_tags" => {"csp-nonce" => '<meta name="csp-nonce" content="">'}}
      end

      it "returns nil when nonce is malformed" do
        nonce = middleware.send(:extract_nonce, env)
        expect(nonce).to be_nil
      end
    end
  end

  describe "#call" do
    let(:env) do
      {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "HTTP_ACCEPT" => "text/html",
        "rack.input" => StringIO.new,
        "CONTENT_TYPE" => "text/html"
      }
    end

    context "when the response has a Content-Type of text/html" do
      it "processes the response body" do
        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/html")
      end
    end

    context "when the response has a Content-Type that is not text/html" do
      let(:app) { ->(env) { [200, {"Content-Type" => "application/json"}, ["{\"key\":\"value\"}"]] } }

      it "does not process the response body" do
        status, headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/json")
        expect(body.first).to include("{\"key\":\"value\"}")
      end
    end
  end
end
