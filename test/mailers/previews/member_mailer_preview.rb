class MemberMailerPreview < ActionMailer::Preview
  def notify_bid
    MemberMailer.with(name: 'Max Müller', email: 'max.mueller@gmx.de', bid: 98.5).notify_bid
  end
end
