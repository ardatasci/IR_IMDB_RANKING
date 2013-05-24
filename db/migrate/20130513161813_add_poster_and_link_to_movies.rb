class AddPosterAndLinkToMovies < ActiveRecord::Migration
  def change
  	add_column :movies, :poster, :string
  	add_column :movies, :link, :string
  end
end
