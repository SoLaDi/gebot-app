class MemberMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def notify_bid
    @name = params[:name]
    @bid = params[:bid]
    mail(to: params[:email], subject: 'Dein Mitgliedsbeitrag wurde erfolgreich gespeichert')
  end
end
