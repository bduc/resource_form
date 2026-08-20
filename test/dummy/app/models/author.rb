class Author < ApplicationRecord
  has_many :books, dependent: :destroy
  has_many :reviews, through: :books

  # Not a database column — mirrors a Devise-style virtual `password`
  # attribute, which is the motivating case for name-pattern inference on
  # attributes resource_class.fields never sees.
  attr_accessor :password
end
