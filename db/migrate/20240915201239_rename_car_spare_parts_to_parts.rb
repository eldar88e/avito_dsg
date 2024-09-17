class RenameCarSparePartsToParts < ActiveRecord::Migration[7.1]
  def change
    rename_table :car_spare_parts, :parts
  end
end
