class Part < ApplicationRecord
  validates :title, presence: true
  validates :min_price, presence: true
  validates :max_price, presence: true
  validates :part_type, presence: true
  validate :validate_images

  has_many :ads, as: :adable, dependent: :destroy
  belongs_to :model_part
  has_many_attached :photos, dependent: :purge
  has_and_belongs_to_many :models

  before_destroy :remove_parts_associations

  def photos_thumb
    photos.variant(resize_to_limit: [50, 50]).processed
  end

  def photos_medium
    photos.variant(resize_to_limit: [400, 400]).processed
  end

  private

  def remove_parts_associations
    models.clear
  end

  def validate_images
    photos.each do |photo|
      next if photo.blank?

      unless %w[image/jpeg image/png image/webp].include?(photo.content_type)
        errors.add(:images, 'must be JPEG, PNG, or WEBP format')
      end
    end
  end
end
