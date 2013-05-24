class MovieDirector < ActiveRecord::Migration
  def up
  	create_table :movies_directors do |t|
  		t.integer :movie_id
  		t.integer :director_id
  	end
  end

  def down
  end
end
