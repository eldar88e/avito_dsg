class CreateModels < ActiveRecord::Migration[7.1]
  def change
    create_table :models do |t|
      t.string :title
      t.references :sub_brand, null: false, foreign_key: true

      t.timestamps
    end
  end
end
