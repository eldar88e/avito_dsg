class ModelPart < ApplicationRecord
  validates :title, presence: true

  has_many :parts, dependent: :destroy
end
