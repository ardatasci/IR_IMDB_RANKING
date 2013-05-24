class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
      t.string :title
      t.text :description
      t.string :duration
      t.float :rating
      t.integer :year
      t.timestamps
    end
  end
end
