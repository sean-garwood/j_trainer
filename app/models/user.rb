class User < ApplicationRecord
  has_secure_password
  # the user has one session
  has_one :session
end
