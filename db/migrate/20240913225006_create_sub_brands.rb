class CreateSubBrands < ActiveRecord::Migration[7.1]
  def change
    create_table :sub_brands do |t|
      t.string :title
      t.references :brand, null: false, foreign_key: true

      t.timestamps
    end
  end
end
