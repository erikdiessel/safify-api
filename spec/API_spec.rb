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
    
    
    describe "GET /status" do
        it "Returns the number of registered users as a hash" do
            get "/status"
            expect(last_response.status).to eq(200)
            expect(last_response.body).to eq("{:registered_users=>2}")
        end
    end
    
    describe "GET /passwords" do
        
        it "Returns the password_list when the password is correct" do
            get "/passwords?username=user1&password=pa$$word37"
            last_response.status.should eq 200
            last_response.body.should eq "My password list"
            nothing_changed
        end
        
        it "Requires a  Username as parameter" do
            get "/passwords" # missing username=blabla
            expect(last_response.status).to eq(400)
            expect(last_response.body).to eq("username is missing, password is missing")
            nothing_changed
        end
        
        it "Requires a Password as parameter" do
            get "/passwords?username=some_user"
            last_response.status.should eq 400
            last_response.body.should eq "password is missing"
            nothing_changed
        end
        
        it "Returns 403 Error for non-existing Users" do
            get "/passwords?username=not_existing_user&password=some_password"
            last_response.status.should eq 403
            last_response.body.should eq "User not found"
            nothing_changed
        end
        
        it "Returns 401 Error when the password is wrong" do
            get "/passwords?username=user1&password=wrong_password"
            last_response.status.should eq 401
            last_response.body.should eq "Authentification failed"
            nothing_changed
        end
        
    end
    
    describe "PUT /passwords" do
        it "Updates the password_list to the given." do
            put "/passwords", "username=user1&password=pa$$word37&password_list=my_new_password_list"
            last_response.status.should eq 200
            last_response.body.should eq "Successfully updated"
            # update happens in database
            User.where(:username => "user1").first.password_list.should eq("my_new_password_list")
            # New password list is now sent:
            get "/passwords?username=user1&password=pa$$word37"
            last_response.status.should eq 200
            last_response.body.should eq "my_new_password_list"
        end
        
        it "Returns an error and updates nothing when given wrong credentials" do
            put "/passwords", "username=user1&password=wrong_password&password_list=evil_stuff"
            last_response.status.should eq 401
            last_response.body.should eq "Authentification failed"
            nothing_changed
        end
        
        it "Returns an error when username does not exist" do
            put "/passwords", "username=not_existing&password=abcd&password_list=blabla"
            last_response.status.should eq 403
            last_response.body.should eq "User not found"
            nothing_changed
        end
        
        it "Returns an error when parameters are missing" do
            put "passwords", ""
            last_response.status.should eq 400
            last_response.body.should eq "username is missing, password is missing, password_list is missing"
            nothing_changed
        end
    end
    
    describe "GET /username_not_used" do
        it "Returns: Username already used, when username already in database" do
            get "/username_not_used?username=user1"
            last_response.status.should eq 409
            last_response.body.should eq "Username already used"
            nothing_changed
        end
        
        it "Returns: Username already used, when username does not exist yet" do
            get "/username_not_used?username=other_user"
            last_response.status.should eq 200
            last_response.body.should eq "Username is free"
            nothing_changed
        end
    end
    
    describe "POST /change_password" do
        it "Changes the password to a new one" do
            post "/change_password", "username=user1&password=pa$$word37&new_password=abcd"
            last_response.status.should eq 201
            last_response.body.should eq "Password successfully changed"
            User.where(:username=>"user1").first.password.should eq "abcd"
        end
        
        it "Does not change the password, when old password is wrong" do
            post "/change_password", "username=user1&password=wrong_password&new_password=abcd"
            last_response.status.should eq 401
            last_response.body.should eq "Authentification failed"
            nothing_changed
        end
        
        it "Returns an error when user does not exist" do
            post "/change_password", "username=not_existing_user&password=abcd&new_password=12345"
            last_response.status.should eq 403
            last_response.body.should eq "User not found"
            nothing_changed
        end
        
        it "Returns an error when parameters are missing" do
            post "/change_password"
            last_response.status.should eq 400
            last_response.body.should eq "username is missing, password is missing, new_password is missing"
            nothing_changed
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
        
        it "Returns an error when username does already exist" do
            post "/register", "username=user1&password=abcd"
            last_response.status.should eq 409
            last_response.body.should eq "Username already used"
            nothing_changed
        end
        
        it "Returns an error when parameters are missing" do
            post "/register", ""
            last_response.status.should eq 400
            last_response.body.should eq "username is missing, password is missing"
            nothing_changed
        end
    end
    
end
