class Drill < ApplicationRecord
  belongs_to :user, required: true
end
