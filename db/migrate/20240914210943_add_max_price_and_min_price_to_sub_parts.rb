class AddMaxPriceAndMinPriceToSubParts < ActiveRecord::Migration[7.1]
  def change
    add_column :sub_parts, :max_price, :integer
    add_column :sub_parts, :min_price, :integer
  end
end
