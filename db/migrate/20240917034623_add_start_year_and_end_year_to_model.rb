class AddStartYearAndEndYearToModel < ActiveRecord::Migration[7.1]
  def change
    add_column :models, :start_year, :integer
    add_column :models, :end_year, :integer
  end
end
