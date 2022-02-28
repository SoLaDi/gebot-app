class Membership
  include ActiveModel::API

  attr_accessor :id, :integer
  attr_accessor :name, :string
  attr_accessor :amount, :float
  attr_accessor :shares, :int
  attr_accessor :has_current_bid, :bool
end
