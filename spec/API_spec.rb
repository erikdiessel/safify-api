require 'spec_helper'
require 'rack/test'
require_relative '../lib/API'

describe API do
    include Rack::Test::Methods
    
    def app
        API
    end
    
    before :each do
        User.delete_all
        # Test fixtures:
        User.create!(
            :username => "user1",
            :password => "pa$$word37",
            :password_list => "My password list"
        )
    end
    
    
    describe "GET /status" do
        it "Returns the number of registered users as a hash" do
            get "/status"
            expect(last_response.status).to eq(200)
            expect(last_response.body).to match(/\{:registered_users=>([0-9])+\}/)
        end
    end
    
    describe "GET /passwords" do
        it "Requires a  Username as parameter" do
            get "/passwords" # missing username=blabla
            expect(last_response.status).to eq(400)
            expect(last_response.body).to eq("missing parameter: username")
        end
        
        it "Requires a Password as parameter" do
            get "/passwords?username=some_user"
            last_response.status.should eq 400
            last_response.body.should eq "missing parameter: password"
        end
        
        it "Returns 403 Error for non-existing Users" do
            get "/passwords?username=not_existing_user&password=some_password"
            last_response.status.should eq 403
            last_response.body.should eq "User not found"
        end
        
        it "Returns 401 Error when the password is wrong" do
            get "/passwords?username=user1&password=wrong_password"
            last_response.status.should eq 401
            last_response.body.should eq "Authentification failed"
        end
        
        it "Returns the password_list when the password is correct" do
            get "/passwords?username=user1&password=pa$$word37"
            last_response.status.should eq 200
            last_response.body.should eq "My password list"
        end
    end
end