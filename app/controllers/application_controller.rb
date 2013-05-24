class ApplicationController < ActionController::Base
  protect_from_forgery


  def get_suggestions
  	if user_signed_in?
  		@suggestions = Movie.where(:id => Suggestion.where(:user_id => current_user.id).collect{|s| s.movie_id})
  	else
  		@suggestions = []
  	end
  end

end
