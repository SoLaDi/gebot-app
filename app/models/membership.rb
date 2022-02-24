class Membership
  include ActiveModel::API

  attr_accessor :id, :integer
  attr_accessor :name, :string
  attr_accessor :amount, :float
end
