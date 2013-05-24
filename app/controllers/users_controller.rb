class UsersController < ApplicationController


	def profile
		@rated_movies = Movie.where(:id => Rate.where(:rater_id => current_user.id).collect{|r| r.rateable_id})
		@rated_directors = Rate.where(:rater_id => current_user.id, :dimension => 'director')
		@rated_authors = Rate.where(:rater_id => current_user.id, :dimension => 'author')
		@suggestions = Movie.where(:id => Suggestion.where(:user_id => current_user.id).collect{|s| s.movie_id})
	end

end