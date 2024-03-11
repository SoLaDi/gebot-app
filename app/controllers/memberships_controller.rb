class MembershipsController < ApplicationController
  def show
    magic_token = params[:id]
    Rails.logger.info "Going to check magic token: #{magic_token}"
    response = conn.get('/api/magic_link/login', { token: magic_token }, headers)

    if response.status != 200
      Rails.logger.warn "Invalid token supplied. Soladi response was: #{response.inspect}"
      redirect_to not_found_path
    else
      data = JSON.parse(response.body, symbolize_names: true)
      membership_id = data[:membership][:id]
      person_id = data[:person_id]
      session[:membership_id] = membership_id
      session[:person_id] = person_id

      Rails.logger.info "User was identified as person '#{person_id}' belonging to membership '#{membership_id}'"

      bids = data[:membership][:bids]
      current_bid = bids.filter { |bid| bid[:start_date] == "2024-04-01" }.first

      if current_bid
        Rails.logger.info "membership has current bid: #{current_bid.inspect}"
        @membership = Membership.new(
          {
            status: person_id.to_s == current_bid[:person_id].to_s ? :bid_placed_by_self : :bid_placed_by_other_member,
            id: data[:membership][:id],
            name: [data[:name], data[:surname]].join(' '),
            email: data[:email],
            amount: current_bid[:amount],
            shares: current_bid[:shares]
          })
      else
        Rails.logger.info "membership has no current bid"

        last_bid = bids.filter { |bid| bid[:start_date] == "2023-04-01" }.first
        # we take last years number of shares or 1 if no old bid is found
        shares = last_bid ? last_bid[:shares] : 1
        default_amount = 103.12

        @membership = Membership.new(
          {
            status: :open_for_bid,
            id: data[:membership][:id],
            name: [data[:name], data[:surname]].join(' '),
            email: data[:email],
            amount: default_amount,
            shares: shares
          })
      end
    end
  end

  def edit
    if !session[:membership_id] || session[:membership_id].to_s != update_params[:id].to_s
      Rails.logger.warn "A bid should be placed for membership id: #{update_params[:id]} but the users session belongs to id: #{session[:membership_id]}"
      redirect_to unauthorized_path
    else
      body = {
        bid: {
          start_date: "2024-04-01",
          end_date: "2025-03-31",
          person_id: session[:person_id],
          membership_id: update_params[:id].to_i,
          amount: update_params[:amount].to_f,
          shares: update_params[:shares].to_i,
        }
      }

      response = conn.post('/api/bids', body.to_json, headers)

      if response.status == 202
        Rails.logger.info("Bid placed successfully")
        MemberMailer.with(name: update_params[:name], email: update_params[:email], bid: update_params[:amount].to_f, membership_id: update_params[:id]).notify_bid.deliver_later
        redirect_to membership_path(params[:id]), success: 'Dein Gebot wurde erfolgreich gespeichert'
      else
        Rails.logger.error("Failed to place bid: #{response.inspect}")
        json_body = JSON.parse(response.body)
        error = json_body['base'].present? && json_body['base'].kind_of?(Array) ? json_body['base'].to_sentence : json_body
        redirect_to membership_path(params[:id]), error: error
      end
    end
  end

  private

  def update_params
    params.require(:membership).permit(:amount, :shares, :id, :name, :email)
  end

  def conn
    Faraday.new(url: ENV['SOLADI_API_URL'])
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Token token=#{ENV['SOLADI_API_SECRET_KEY']}"
    }
  end
end
