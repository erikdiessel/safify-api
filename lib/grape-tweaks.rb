# Send Access-Control-Allow-Origin headers also on errors and options requests

class Grape::Middleware::Error
   def error_response(error = {})
      status = error[:status] || options[:default_status]
      message = error[:message] || options[:default_message]
      # added Access-Control-Allow-Origin 
      headers = {'Content-Type' => content_type, 'Access-Control-Allow-Origin' => '*'}
      headers.merge!(error[:headers]) if error[:headers].is_a?(Hash)
      backtrace = error[:backtrace] || []
      rack_response(format_message(message, backtrace), status, headers)
   end
end

class Grape::API
   def add_head_not_allowed_methods
      allowed_methods = Hash.new{|h,k| h[k] = [] }
      resources       = self.class.endpoints.map do |endpoint|
         endpoint.options[:app] && endpoint.options[:app].respond_to?(:endpoints) ?
         endpoint.options[:app].endpoints.map(&:routes) :
         endpoint.routes
      end
      resources.flatten.each do |route|
        allowed_methods[route.route_compiled] << route.route_method
      end
      allowed_methods.each do |path_info, methods|
         if methods.include?('GET') && ! methods.include?("HEAD") && ! self.class.settings[:do_not_route_head]
            methods = methods | [ 'HEAD' ]
         end
         allow_header = (["OPTIONS"] | methods).join(", ")
         unless methods.include?("OPTIONS") || self.class.settings[:do_not_route_options]
            # changed status to 200, added Access-Control-Allow-Headers
            @route_set.add_route( proc { [200, { 
                  'Allow' => allow_header,
                  'Access-Control-Allow-Origin' => '*',
                  'Access-Control-Allow-Methods' => 'GET, OPTIONS, PUT, POST, DELETE',
                  'Access-Control-Allow-Headers' => 'accept, origin, content-type'
               }, []]}, {
               :path_info      => path_info,
               :request_method => "OPTIONS"
            })
         end
         not_allowed_methods = %w(GET PUT POST DELETE PATCH HEAD) - methods
         not_allowed_methods << "OPTIONS" if self.class.settings[:do_not_route_options]
         not_allowed_methods.each do |bad_method|
         @route_set.add_route( proc { [405, { 'Allow' => allow_header, 'Content-Type' => 'text/plain' }, []]}, {
            :path_info      => path_info,
            :request_method => bad_method
         })
         end
      end
   end
end