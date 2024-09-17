class AddTitleToAds < ActiveRecord::Migration[7.1]
  def change
    add_column :ads, :title, :string
    add_index :ads, :title
  end
end
