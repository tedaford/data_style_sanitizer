require_relative "data_style_sanitizer/processor"

module DataStyleSanitizer
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)

      if html_response?(headers)
        body = +""
        response.each { |part| body << part }

        nonce = extract_nonce_from_env(env)
        processed = Processor.new(body, nonce: nonce).process

        headers["Content-Length"] = processed.bytesize.to_s
        [status, headers, [processed]]
      else
        [status, headers, response]
      end
    end

    private

    def html_response?(headers)
      headers["Content-Type"]&.include?("text/html")
    end

    def extract_nonce_from_env(env)
      if env["action_dispatch.content_security_policy_nonce"].respond_to?(:call)
        env["action_dispatch.content_security_policy_nonce"].call(:style)
      else
        nil
      end
    end
  end
end
