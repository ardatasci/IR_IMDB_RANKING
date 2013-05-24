class MovieGenre < ActiveRecord::Migration
  def up
  	create_table :movies_genres do |t|
  		t.integer :movie_id
  		t.integer :genre_id
  	end
  end

  def down
  end
end
