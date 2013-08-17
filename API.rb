require 'grape'
require './User'
require './grape-tweaks'

module Authentification

   def authentificate!
      if not password_correct?(params[:username], params[:password])
         error! 'Authentification failed', 401
      end
   end
  
   def password_correct?(username, password)
      user = get_user!(username)
      user.password_correct?(password)
   end
  
   def get_user!(username)
      user = User.where(:username => username).first
      if user
         user
      else
         error! 'User not found', 403
      end
   end
  
end

class API < Grape::API
   format :txt
   helpers Authentification
   
   before do
      header "Access-Control-Allow-Origin", "*"
   end
   
   
   params do
      requires :username, :type => String
      requires :password, :type => String
   end
   
   resource :passwords do     
      
      get do
         authentificate!
         user = get_user!(params[:username])
         user.password_list || '{}'
      end
      
      
      params do
         requires :password_list, :type => String
      end
      
      put do
         authentificate!
         user = get_user!(params[:username])
         user.update_attributes :password_list => params[:password_list]
         'Successfully updated'
      end
      
   end
   
   
   params do
      requires :username, :type => String
      requires :password, :type => String
   end    
   
   post 'register' do
      begin
         User.create!(
            :username => params[:username],
            :password => params[:password]
         )
      rescue
         error! 'Username already used', 409
      end
      'Successfully registered'
   end
   
   
   get 'status' do
      {
         :registered_users => User.count
      }
   end
   
   
   params do
      requires :username, :type => String   
   end
   
   get 'username_not_used' do
      user = User.where(:username => params[:username]).first
      if user
         error! 'Username already used', 409
      else
         'Username is free'
      end
   end
   
   
   params do
      requires :username, :type => String
      requires :password, :type => String
      requires :new_password, :type => String
   end
   
   post 'change_password' do
      authentificate!
      user = User.where(:username => params[:username]).first
      user.update_attributes :password => params[:new_password]
      'Password successfully changed'
   end
   
end