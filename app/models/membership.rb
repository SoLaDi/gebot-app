class Membership
  include ActiveModel::API

  # can be [:open_for_bid, :bid_placed_by_other_member, :bid_placed_by_self]
  attr_accessor :status, :string

  attr_accessor :id, :integer
  attr_accessor :name, :string
  attr_accessor :email, :string
  attr_accessor :amount, :float
  attr_accessor :shares, :int
end
