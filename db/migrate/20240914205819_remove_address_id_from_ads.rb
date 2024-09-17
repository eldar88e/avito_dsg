class RemoveAddressIdFromAds < ActiveRecord::Migration[7.1]
  def change
    remove_index :ads, :address_id
    remove_column :ads, :address_id, :integer
  end
end
