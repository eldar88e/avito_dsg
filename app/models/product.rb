class Product < ApplicationRecord
  before_validation :set_defaults
  before_save :cleanup_description

  validates :title, presence: true
  validates :description, presence: true
  validates :price, presence: true, numericality: { only_integer: true }

  has_one_attached :image, dependent: :purge
  has_many :ads, as: :adable, dependent: :destroy
  belongs_to :user

  self.inheritance_column = :type_

  def self.ransackable_attributes(auth_object = nil)
    ["active", "ad_status", "ad_type", "allow_email", "category", "condition", "contact_method", "created_at", "description", "goods_type", "id", "id_value", "localization", "platform", "price", "title", "type", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["ads", "image_attachment", "image_blob", "user"]
  end

  private

  def set_defaults
    self.ad_status   = nil if ad_status.blank?
    self.category    = nil if category.blank?
    self.goods_type  = nil if goods_type.blank?
    self.ad_type     = nil if ad_type.blank?
    self.condition   = nil if condition.blank?
    self.allow_email = nil if allow_email.blank?
  end

  def cleanup_description
    if description.present?
      description.squeeze!(' ')
      description.chomp!
    end
  end
end
