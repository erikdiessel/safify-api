require 'mongoid'

class User
   include Mongoid::Document
   
   field :username, :type => String
   field :password, :type => String
   field :password_list, :type => String
   
   validates :username, :presence => true, :uniqueness => true
   validate :password, :presence => true
   
   def password_correct?(password)
      self.password == password
   end
end