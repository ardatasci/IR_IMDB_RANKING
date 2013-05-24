class CreateSuggestions < ActiveRecord::Migration
  def change
    create_table :suggestions do |t|
      t.integer :user_id
      t.integer :movie_id
      t.timestamps
    end
  end
end
