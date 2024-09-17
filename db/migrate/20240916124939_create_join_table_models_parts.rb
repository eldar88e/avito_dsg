class CreateJoinTableModelsParts < ActiveRecord::Migration[7.1]
  def change
    create_join_table :models, :parts do |t|
      t.index :model_id
      t.index :part_id
    end

    change_column_null :models_parts, :model_id, false
    change_column_null :models_parts, :part_id, false

    add_foreign_key :models_parts, :models
    add_foreign_key :models_parts, :parts
  end
end
