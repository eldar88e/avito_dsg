class UpdateAds < ActiveRecord::Migration[7.1]
  def change
    change_column_null :ads, :file_id, true

    add_column :ads, :banned, :boolean, default: false, null: false

    add_column :ads, :banned_until, :datetime
  end
end
