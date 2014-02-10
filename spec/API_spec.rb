require 'spec_helper'
require '../lib/API'

describe API do
    include Rack::Test::Methods
    
    def app
        API
    end 
    
    
    describe "GET /status" do
        it "Returns the number of registered users as a hash" do
            get "/status"
            expect(last_response.status).to eq(200)
            expect(last_response.body).to match(/{:registered_users}=>([0-9]+}/)
        end
    end
end