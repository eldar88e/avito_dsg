class Model < ApplicationRecord
  validates :title, presence: true
  validates :parts, presence: true

  belongs_to :sub_brand
  has_and_belongs_to_many :parts

  before_destroy :remove_parts_associations

  private

  def remove_parts_associations
    parts.clear
  end
end
