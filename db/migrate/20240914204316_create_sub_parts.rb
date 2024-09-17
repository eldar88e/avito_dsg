class CreateSubParts < ActiveRecord::Migration[7.1]
  def change
    create_table :sub_parts do |t|
      t.string :title
      t.text :description
      t.string :part_type

      t.timestamps
    end
  end
end
