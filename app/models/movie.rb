class Movie < ActiveRecord::Base
 
require 'json'
require "open-uri"
require 'rubygems'
require 'tfidf'
require "unicode_utils"
require "fast-stemmer"

ajaxful_rateable :stars => 5, :dimensions => [:subject, :director, :author, :actor], :allow_update => true



attr_accessible :title, :description, :rating, :duration, :poster, :link, :year, :id
validates_uniqueness_of :title

IMDB_ENDPOINT = "http://imdbapi.org?plot=full&type=json&title="


  def poster_path
    "images/" + self.poster.to_s + ".png"
  end

  def self.get_movies
  	data = File.read("crawler.json")
  	movies = JSON.parse(data)

  	movies.each do |movie|
  		puts "Movie from file #{movie}"

  		movie_info = JSON.parse(open(IMDB_ENDPOINT + movie["name"].gsub(" ","%20")).read())
  	   puts "Movie desc size #{movie_info.first['plot'].nil?}"
  		next if movie_info.is_a?(Hash)
      next if movie_info.first['plot'].nil?
      poster_path = Time.now
  		movie_data = Movie.new(:title => movie_info.first['title'],
  								:poster => poster_path,
  								:link => movie_info.first['imdb_url'],
  								:description => movie_info.first['plot'],
  								:rating => movie_info.first['rating'],
  								:duration => movie_info.first['runtime'].try(:first), 
  								:year => movie_info.first['year'].to_i)
       movie_data.save

      unless movie_info.first['poster'].nil?
        open("public/images/" + poster_path.to_s + '.png', 'wb') do |file|
            file << open(movie_info.first['poster']).read
        end
      end 		
  		puts "NAME #{movie_info.first['title']}"
  		if movie_info.first['genres']
	  		movie_info.first['genres'].each do |genre|
	  			genre_data = Genre.find_or_create_by_name(genre)
	  			movie_genre = GenresMovies.find_or_create_by_movie_id_and_genre_id(movie_data.id,
	  								genre_data.id)
	 
	  		end
  		end
  		if movie_info.first['directors']
	  		movie_info.first['directors'].each do |director|
	  			director_data = Director.find_or_create_by_name(director)
	  			movie_director = DirectorsMovies.find_or_create_by_movie_id_and_director_id(movie_data.id,
	  								director_data.id)

	  		end
  		end

  		if movie_info.first['writers']
	  		movie_info.first['writers'].each do |writer|
	  			writer_data = Writer.find_or_create_by_name(writer)
	  			movie_writer = WritersMovies.find_or_create_by_movie_id_and_writer_id( movie_data.id,
	  								 writer_data.id)
	  		end
  		end

  		if movie_info.first['actors']
	  		movie_info.first['actors'].each do |actor|
	  			actor_data = Actor.find_or_create_by_name(actor)
	  			movie_actor = ActorsMovies.find_or_create_by_movie_id_and_actor_id(movie_data.id,
	  								actor_data.id)
	  		end
	  	end
  	end
  end





def self.create_movie_indexes
    stop_words = []
    File.open("stop_word_list.txt", "r").each_line do |line|
      stop_words.push(line.to_s.chomp )
    end
    @@document_array = []
    data = []
    Movie.all.each do |mov|
      data_f = UnicodeUtils.downcase(mov.description, :en)
      data_f += Actor.select('name').where(:id =>ActorsMovies.where(:movie_id => mov.id).collect{|a| a.actor_id}).collect{|m| UnicodeUtils.downcase(m.name.gsub(" ", "_"), :en)}.to_s  
      data_f += Genre.select('name').where(:id =>GenresMovies.where(:movie_id => mov.id).collect{|a| a.genre_id}).collect{|m| UnicodeUtils.downcase(m.name.gsub(" ", "_"), :en)}.to_s
      data_f += Director.select('name').where(:id =>DirectorsMovies.where(:movie_id => mov.id).collect{|a| a.director_id}).collect{|m| UnicodeUtils.downcase(m.name.gsub(" ", "_"), :en)}.to_s   
      data_f += Writer.select('name').where(:id =>WritersMovies.where(:movie_id => mov.id).collect{|a| a.writer_id}).collect{|m| UnicodeUtils.downcase(m.name.gsub(" ", "_"), :en)}.to_s
      words = data_f.gsub("\"", "").gsub("\\", "").gsub("[", " ").gsub("]"," ").gsub(","," ").gsub(".", " ").split(/\W+/)
      extr =  (words - stop_words).collect{|m| UnicodeUtils.downcase(m, :en)}.to_s
      doc  = TfIdfSimilarity::Document.new(extr)
      @@document_array.push(doc)
    end
  end

  def self.user_ratings
    if self.class_variables.size == 0
      self.create_movie_indexes
    end
    Suggestion.delete_all
    raters = Rate.select("rater_id").group("rater_id")
    raters.each do |rater|
        rates = Rate.where(:rater_id => rater.rater_id, :dimension => 'subject')
        rated_movies = rates.collect{|r| r.rateable_id}
        rated_movie_descriptions = []
        rated_movies.each do |movie_id|
          movie = Movie.find_by_id(movie_id)
          Rate.where(:rateable_id => movie.id, :rater_id => rater.rater_id, :dimension => 'subject').first.stars.times do
              rated_movie_descriptions.push(movie.description)
          end
          rated_movie_genres = Genre.where(:id => GenresMovies.where(:movie_id => movie_id).collect{|a| a.genre_id})
          2.times do 
            rated_movie_descriptions.push(rated_movie_genres.collect{|a| a.name})
          end
        end
        actor_rates = Rate.where(:rater_id => rater.rater_id, :dimension => 'actor')
        rated_movies = actor_rates.collect{|r| r.rateable_id}
        rated_movies.each do |movie_id|
          movie = Movie.find_by_id(movie_id)
          rated_movie_actors = Actor.where(:id => ActorsMovies.where(:movie_id => movie_id).collect{|a| a.actor_id})
           Rate.where(:rateable_id => movie.id, :rater_id => rater.rater_id, :dimension => 'actor').first.stars.times do 
            rated_movie_descriptions.push(rated_movie_actors.collect{|a| a.name.gsub(" ", "_")})
          end
        end
        director_rates = Rate.where(:rater_id => rater.rater_id, :dimension => 'director')
        rated_movies = director_rates.collect{|r| r.rateable_id}
        rated_movies.each do |movie_id|
          movie = Movie.find_by_id(movie_id)
          rated_movie_directors = Director.where(:id => DirectorsMovies.where(:movie_id => movie_id).collect{|a| a.director_id})
           Rate.where(:rateable_id => movie.id, :rater_id => rater.rater_id, :dimension => 'director').first.stars.times do
            rated_movie_descriptions.push(rated_movie_directors.collect{|a| a.name.gsub(" ", "_")})
          end
        end
        writer_rates = Rate.where(:rater_id => rater.rater_id, :dimension => 'author')
        rated_movies = writer_rates.collect{|r| r.rateable_id}
        rated_movies.each do |movie_id|
          movie = Movie.find_by_id(movie_id)
          rated_movie_authors = Writer.where(:id => WritersMovies.where(:movie_id => movie_id).collect{|a| a.writer_id})
           Rate.where(:rateable_id => movie.id, :rater_id => rater.rater_id, :dimension => 'author').first.stars.times do
            rated_movie_descriptions.push(rated_movie_authors.collect{|a| a.name.gsub(" ", "_")})
          end
        end
        #corpus = TfIdfSimilarity::Collection.new
        data = []
        corpus = TfIdfSimilarity::Collection.new
        user_data = rated_movie_descriptions.flatten.collect{|m| UnicodeUtils.downcase(m, :en)}
        corpus << TfIdfSimilarity::Document.new(user_data.map(&:inspect).join(' '))
        
        @@document_array.each do |desc|
         corpus << desc
        end   
        array = []
        similarity_matrix = corpus.similarity_matrix

        similarity_matrix.size.first.times do |i|
          array.push(similarity_matrix[0, i])
        end    
        
        hash = Hash[array.map.with_index.to_a]   
        #hash =  hash.reject!{ |k|  k < 0.5 } 
        sorted_hash = hash.sort_by { |index, val| index } 
         user = User.find_by_id(rater.rater_id)     
        t = 0
        File.open("movie_terms/" + user.email.to_s + ".dat", "w+") do |f|
          str = ""
        sorted_hash.reverse.each_with_index do |value, index|
          rated_movie_ids = Rate.select("rateable_id").where(:rater_id => rater.rater_id).group("rateable_id").collect{|r| r.rateable_id}
         
          break if t > 4 
          unless value[1] == 0 || rated_movie_ids.include?(value[1])
            
              str << Movie.find(value[1]).title.to_s + " = " + value[0].to_s + "\n" 
              
            
           t += 1
           s = Suggestion.new(:movie_id => value[1], :user_id => rater.rater_id)
           s.save
          end
        end
        f.write(str)
      end
      end
  end


  def self.get_user_ratings
    Suggestion.delete_all
    raters = Rate.select("rater_id").group("rater_id")
    raters.each do |rater|
        rates = Rate.where(:rater_id => rater.rater_id, :dimension => 'subject')
        rated_movies = rates.collect{|r| r.rateable_id}
        rated_movie_descriptions = []
        rated_movies.each do |movie_id|
          movie = Movie.find_by_id(movie_id)
          Rate.where(:rateable_id => movie.id, :rater_id => rater.rater_id, :dimension => 'subject').first.stars.times do
              rated_movie_descriptions.push(movie.description)
          end
          rated_movie_genres = Genre.where(:id => GenresMovies.where(:movie_id => movie_id).collect{|a| a.genre_id})
          2.times do 
            rated_movie_descriptions.push(rated_movie_genres.collect{|a| a.name})
          end
        end

        actor_rates = Rate.where(:rater_id => rater.rater_id, :dimension => 'actor')
        rated_movies = actor_rates.collect{|r| r.rateable_id}
        rated_movies.each do |movie_id|
          movie = Movie.find_by_id(movie_id)
          rated_movie_actors = Actor.where(:id => ActorsMovies.where(:movie_id => movie_id).collect{|a| a.actor_id})
           Rate.where(:rateable_id => movie.id, :rater_id => rater.rater_id, :dimension => 'actor').first.stars.times do 
            rated_movie_descriptions.push(rated_movie_actors.collect{|a| a.name.gsub(" ", "_")})
          end
        end

        director_rates = Rate.where(:rater_id => rater.rater_id, :dimension => 'director')
        rated_movies = director_rates.collect{|r| r.rateable_id}
        rated_movies.each do |movie_id|
          movie = Movie.find_by_id(movie_id)
          rated_movie_directors = Director.where(:id => DirectorsMovies.where(:movie_id => movie_id).collect{|a| a.director_id})
           Rate.where(:rateable_id => movie.id, :rater_id => rater.rater_id, :dimension => 'director').first.stars.times do
            rated_movie_descriptions.push(rated_movie_directors.collect{|a| a.name.gsub(" ", "_")})
          end
        end


        writer_rates = Rate.where(:rater_id => rater.rater_id, :dimension => 'author')
        rated_movies = writer_rates.collect{|r| r.rateable_id}
        rated_movies.each do |movie_id|
          movie = Movie.find_by_id(movie_id)
          rated_movie_authors = Writer.where(:id => WritersMovies.where(:movie_id => movie_id).collect{|a| a.writer_id})
           Rate.where(:rateable_id => movie.id, :rater_id => rater.rater_id, :dimension => 'author').first.stars.times do
            rated_movie_descriptions.push(rated_movie_authors.collect{|a| a.name.gsub(" ", "_")})
          end
        end

        corpus = TfIdfSimilarity::Collection.new
        data = []
        Movie.all.each do |mov|
          data_f = UnicodeUtils.downcase(mov.description, :en)
          data_f += Actor.select('name').where(:id =>ActorsMovies.where(:movie_id => mov.id).collect{|a| a.actor_id}).collect{|m| UnicodeUtils.downcase(m.name.gsub(" ", "_"), :en)}.to_s  
          data_f += Genre.select('name').where(:id =>GenresMovies.where(:movie_id => mov.id).collect{|a| a.genre_id}).collect{|m| UnicodeUtils.downcase(m.name.gsub(" ", "_"), :en)}.to_s
          data_f += Director.select('name').where(:id =>DirectorsMovies.where(:movie_id => mov.id).collect{|a| a.director_id}).collect{|m| UnicodeUtils.downcase(m.name.gsub(" ", "_"), :en)}.to_s   
          data_f += Writer.select('name').where(:id =>WritersMovies.where(:movie_id => mov.id).collect{|a| a.writer_id}).collect{|m| UnicodeUtils.downcase(m.name.gsub(" ", "_"), :en)}.to_s
        
          data.push(data_f)
        end
          user_data = rated_movie_descriptions.flatten.collect{|m| UnicodeUtils.downcase(m, :en)}
        corpus << TfIdfSimilarity::Document.new(user_data.map(&:inspect).join(' '))
        
        data.each do |desc|
          File.open("tf_idf", "w+") do |f|
              f.write(TfIdfSimilarity::Document.new(desc.gsub("\"", "").gsub("\\", "").gsub("[", " ").gsub("]"," ").gsub(","," ").gsub(".", " ")).inspect)
          end
          #doc =  TfIdfSimilarity::Document.new(desc.gsub("\"", "").gsub("\\", "").gsub("[", " ").gsub("]"," ").gsub(","," ").gsub(".", " "))
          doc  = File.read("tf_idf")
         corpus << TfIdfSimilarity::Document.type_cast(doc) 
        end

        array = []
        similarity_matrix = corpus.similarity_matrix
        similarity_matrix.size.first.times do |i|
          array.push(similarity_matrix[0, i])
        end    
        hash = Hash[array.map.with_index.to_a]   
        #hash =  hash.reject!{ |k|  k < 0.5 } 
        sorted_hash = hash.sort_by { |index, val| index }      
       
        sorted_hash.reverse.each_with_index do |value, index|
          rated_movie_ids = Rate.select("rateable_id").where(:rater_id => rater.rater_id).group("rateable_id").collect{|r| r.rateable_id}

          break if index > 5 
          unless value[1] == 0 || rated_movie_ids.include?(value[1])
           s = Suggestion.new(:movie_id => value[1], :user_id => rater.rater_id)
           s.save
          end
        end
      end
    end
end
