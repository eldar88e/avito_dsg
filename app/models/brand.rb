class Brand < ApplicationRecord
  validates :title, presence: true

  has_many :sub_brands, dependent: :destroy
end
