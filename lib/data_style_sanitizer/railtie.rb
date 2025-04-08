require "rails/railtie"

module DataStyleSanitizer
  class Railtie < Rails::Railtie
    initializer "data_style_sanitizer.middleware" do |app|
      app.middleware.insert_after ActionDispatch::ContentSecurityPolicy::Middleware, Middleware
    end
  end

  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)

      if headers["Content-Type"]&.include?("text/html")
        body = +""
        response.each { |part| body << part }

        nonce = extract_nonce(env)
        new_body = DataStyleSanitizer.sanitize_html(body, nonce: nonce)

        headers["Content-Length"] = new_body.bytesize.to_s
        [status, headers, [new_body]]
      else
        [status, headers, response]
      end
    end

    private

    def extract_nonce(env)
      env.dig("action_dispatch.content_security_policy_nonce", :style)
    end
  end
end
