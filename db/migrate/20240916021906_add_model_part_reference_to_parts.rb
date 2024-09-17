class AddModelPartReferenceToParts < ActiveRecord::Migration[7.1]
  def change
    add_reference :parts, :model_part, null: false, foreign_key: true
  end
end
