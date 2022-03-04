class MemberMailer < ApplicationMailer
  def notify_bid
    @name = params[:name]
    @bid = params[:bid]
    @membership_id = params[:membership_id]
    mail(to: params[:email], subject: 'Dein Mitgliedsbeitrag wurde erfolgreich gespeichert')
  end
end
