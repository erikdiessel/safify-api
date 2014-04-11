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