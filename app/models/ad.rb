class Ad < ApplicationRecord
  validates :title, presence: true

  belongs_to :user
  belongs_to :store
  belongs_to :adable, polymorphic: true
  has_one_attached :image, dependent: :purge

  enum deleted: { active: 0, deleted: 1 }
end