class Grape::Middleware::Error
    def error_response(error = {})
        status = error[:status] || options[:default_status]
        message = error[:message] || options[:default_message]
        # include Access-Control-Header
        headers = { 'Content-Type' => content_type,
                    'Access-Control-Allow-Origin' => "*" }
        headers.merge!(error[:headers]) if error[:headers].is_a?(Hash)
        backtrace = error[:backtrace] || []
        rack_response(format_message(message, backtrace), status, headers)
    end    
end