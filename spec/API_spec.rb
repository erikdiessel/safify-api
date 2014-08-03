require 'spec_helper'
require 'rack/test'
require_relative '../lib/API'

describe API do
    include Rack::Test::Methods
    
    def app
        API
    end
    
    def nothing_changed
        User.count.should be 2

        # verify user1
        user = User.where(:username=>"user1").first
        user.password.should      eq "pa$$word37"
        user.password_list.should eq "My password list"

        # verify another user
        another_user = User.where(:username=>"another_user").first
        another_user.password.should      eq "abcde12345"
        another_user.password_list.should eq "Super secret passwords: Blabla"
    end
    
    def includes_access_control_headers
        last_response["Access-Control-Allow-Origin"].should eq "*"
    end
    
    before :each do
        User.delete_all
        # Test fixtures:
        User.create!(
            :username      => "user1",
            :password      => "pa$$word37",
            :password_list => "My password list"
        )

	User.create!(
            :username      => "another_user",
            :password      => "abcde12345",
            :password_list => "Super secret passwords: Blabla"
        )
    end
    
    after :each do
        includes_access_control_headers    
    end
    
    
    describe "GET /status" do
        it "Returns the number of registered users as a hash" do
            get "/status"
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq("{:registered_users=>2}")
        end
    end
    
    describe "GET /passwords" do
        
        context "The password is correct" do
            it "Returns the password_list" do
                get "/passwords?username=user1&password=pa$$word37"
                last_response.status.should eq 200
                last_response.body.should eq "My password list"
                nothing_changed
            end
        end
        
        context "The username parameter is not present" do
            it "Returns a 400 error" do
                get "/passwords" # missing username=blabla
                expect(last_response.status).to eq(400)
                expect(last_response.body).to eq("username is missing, password is missing")
                nothing_changed
            end
        end
        
        context "The password parameter is not present" do
            it "Returns a 400 error" do
                get "/passwords?username=some_user"
                last_response.status.should eq 400
                last_response.body.should eq "password is missing"
                nothing_changed
            end
        end
        
        context "The user with this username does not exist" do
            it "Returns a 403 error" do
                get "/passwords?username=not_existing_user&password=some_password"
                last_response.status.should eq 403
                last_response.body.should eq "User not found"
                nothing_changed
            end
        end
        
        context "The password is wrong" do
            it "Returns a 401 error " do
                get "/passwords?username=user1&password=wrong_password"
                last_response.status.should eq 401
                last_response.body.should eq "Authentification failed"
                nothing_changed
            end
        end
    
    
    
    end
    
    describe "PUT /passwords" do
        context "The given credentials are correct" do
            it "Updates the password_list to the given." do
                post "/passwords", "username=user1&password=pa$$word37&password_list=my_new_password_list"
                last_response.status.should eq 201
                last_response.body.should eq "Successfully updated"
                # update happens in database
                User.where(:username => "user1").first.password_list.should eq("my_new_password_list")
                # New password list is now sent:
                get "/passwords?username=user1&password=pa$$word37"
                last_response.status.should eq 200
                last_response.body.should eq "my_new_password_list"
            end
        end
        
        context "The credentials are wrong" do
            it "Returns a 401 error" do
                post "/passwords", "username=user1&password=wrong_password&password_list=evil_stuff"
                last_response.status.should eq 401
                last_response.body.should eq "Authentification failed"
                nothing_changed
            end
        end
        
        context "The user with the given username does not exist" do
            it "Returns a 403 error" do
                post "/passwords", "username=not_existing&password=abcd&password_list=blabla"
                last_response.status.should eq 403
                last_response.body.should eq "User not found"
                nothing_changed
            end
        end
        
        context "the password is missing" do
            it "returns a 400 error" do
                post "passwords", ""
                last_response.status.should eq 400
                last_response.body.should eq "username is missing, password is missing, password_list is missing"
                nothing_changed
            end
        end
    
    end
    
    describe "GET /username_not_used" do
        
        context "The username does not exist yet" do
            it "returns with status code 200" do
                get "/username_not_used?username=other_user"
                last_response.status.should eq 200
                last_response.body.should eq "Username is free"
                nothing_changed
            end
        end
        
        context "the username is already in the database" do
            it "returns a 409 error" do
                get "/username_not_used?username=user1"
                last_response.status.should eq 409
                last_response.body.should eq "Username already used"
                nothing_changed
            end
        end
    end
    
    describe "POST /change_password" do
        context "the credentials are correct" do
            it "changes the password to a new one" do
                post "/change_password", "username=user1&password=pa$$word37&new_password=abcd"
                last_response.status.should eq 201
                last_response.body.should eq "Password successfully changed"
                User.where(:username=>"user1").first.password.should eq "abcd"
            end
        end
        
        context "the old password is wrong" do
            it "does not change the password" do
                post "/change_password", "username=user1&password=wrong_password&new_password=abcd"
                last_response.status.should eq 401
                last_response.body.should eq "Authentification failed"
                nothing_changed
            end
        end
        
        context "the user does not exist" do
            it "return a 403 error" do
                post "/change_password", "username=not_existing_user&password=abcd&new_password=12345"
                last_response.status.should eq 403
                last_response.body.should eq "User not found"
                nothing_changed
            end
        end
        
        context "parameters are missing" do
            it "Returns a 400 error" do
                post "/change_password"
                last_response.status.should eq 400
                last_response.body.should eq "username is missing, password is missing, new_password is missing"
                nothing_changed
            end
        end
    end
    
    describe "POST /register" do
        it "Creates a new user" do
            post "/register", "username=user2&password=abcd"
            last_response.status.should eq 201
            last_response.body.should eq "Successfully registered"
            user = User.where(:username=>"user2").first
            user.password.should eq "abcd"
            user.password_list.should eq nil
            User.count.should eq 3
        end
        
        context "the username does already exist" do
            it "Returns a 409 error" do
                post "/register", "username=user1&password=abcd"
                last_response.status.should eq 409
                last_response.body.should eq "Username already used"
                nothing_changed
            end
        end
        
        context "parameters are missing" do
            it "Returns a 400 error" do
                post "/register", ""
                last_response.status.should eq 400
                last_response.body.should eq "username is missing, password is missing"
                nothing_changed
            end
        end
    end
    
end
