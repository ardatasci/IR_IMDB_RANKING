class MovieActor < ActiveRecord::Migration
  def up
  	create_table :movies_actors do |t|
  		t.integer :movie_id
  		t.integer :actor_id
  	end
  end

  def down
  end
end
