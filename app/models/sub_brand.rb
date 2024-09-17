class SubBrand < ApplicationRecord
  validates :title, presence: true

  belongs_to :brand
  has_many :models, dependent: :destroy
end
