class CreateWriters < ActiveRecord::Migration
  def change
    create_table :writers do |t|
    	t.string :name
      t.timestamps
    end
  end
end
