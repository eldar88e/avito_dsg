class AddTemplateTitleToPart < ActiveRecord::Migration[7.1]
  def change
    add_column :parts, :template_title, :string
  end
end
