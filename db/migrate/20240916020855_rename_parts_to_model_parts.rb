class RenamePartsToModelParts < ActiveRecord::Migration[7.1]
  def change
    rename_table :parts, :model_parts
  end
end
