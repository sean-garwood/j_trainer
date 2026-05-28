class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :drills, dependent: :destroy

  # TODO: improve normalization/validation
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true
end
