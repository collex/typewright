class LoginController < ApplicationController
  def login
	  federation = params[:federation]
	  user_id = params[:user_id]
	  user = User.find_by_federation_and_orig_id(federation, user_id)
	  if user == nil
		  user = User.create({:federation => federation, :orig_id => user_id})
	  end
	  session[:user_id] = user.id
  end

end
