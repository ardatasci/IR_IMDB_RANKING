class MoviesController < ApplicationController
  before_filter :get_suggestions
  def index
  	@movies = Movie.paginate(:page => params[:page], :per_page =>12)

  end

  def rate
    @movie = Movie.find(params[:id])
    @movie.rate(params[:stars], current_user, params[:dimension])
    respond_to do |format|
    	format.js {render 'rate', :locals => {:dom_id => @movie.wrapper_dom_id(params), :movie => @movie, :dimension =>  params[:dimension]}} 
    end
  end

  def show
    puts "params #{params}"
  	@movie = Movie.find(params[:id])
    @actors = Actor.where(:id => ActorsMovies.where(:movie_id => params[:id]).collect{|a| a.actor_id})
     @genres = Genre.where(:id => GenresMovies.where(:movie_id => params[:id]).collect{|a| a.genre_id})
      @authors = Writer.where(:id => WritersMovies.where(:movie_id => params[:id]).collect{|a| a.writer_id})
       @directors = Director.where(:id => DirectorsMovies.where(:movie_id => params[:id]).collect{|a| a.director_id})



  end
  
end
