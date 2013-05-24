class MovieWriter < ActiveRecord::Migration
  def up
  	create_table :movies_writers do |t|
  		t.integer :movie_id
  		t.integer :writer_id
  	end
  end

  def down
  end
end
