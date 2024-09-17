class CreateCarSpareParts < ActiveRecord::Migration[7.1]
  def change
    create_table :car_spare_parts do |t|
      t.string :title

      t.timestamps
    end
  end
end
