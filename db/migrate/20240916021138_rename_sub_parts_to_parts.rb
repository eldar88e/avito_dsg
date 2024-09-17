class RenameSubPartsToParts < ActiveRecord::Migration[7.1]
  def change
    rename_table :sub_parts, :parts
  end
end
