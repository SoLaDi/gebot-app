class MembershipsController < ApplicationController
  def show
    flash[:notice] = nil
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
      current_bid = bids.filter { |bid| bid[:start_date] == "2022-04-01" }.first

      if current_bid
        Rails.logger.info "membership has current bid: #{current_bid.inspect}"
        @membership = Membership.new(
          {
            id: data[:membership][:id],
            name: [data[:name], data[:surname]].join(' '),
            amount: current_bid[:amount],
            shares: current_bid[:shares],
            has_current_bid: true
          })
      else
        Rails.logger.info "membership has no current bid"

        last_bid = bids.filter { |bid| bid[:start_date] == "2021-04-01" }.first
        # we take last years number of shares or 1 if no old bid is found
        shares = last_bid ? last_bid[:shares] : 1
        default_amount = 95.0

        @membership = Membership.new(
          {
            id: data[:membership][:id],
            name: [data[:name], data[:surname]].join(' '),
            amount: default_amount,
            shares: shares,
            has_current_bid: false
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
          start_date: "2022-04-01",
          end_date: "2023-03-31",
          person_id: session[:person_id],
          membership_id: update_params[:id].to_i,
          amount: update_params[:amount].to_f,
          shares: update_params[:shares].to_i,
        }
      }

      response = conn.post('/api/bids', body.to_json, headers)

      if response.status == 202
        Rails.logger.info("Bid placed successfully")
        flash[:notice] = 'Gebot aktualisiert!'
      else
        Rails.logger.error("Failed to place bid: #{response.inspect}")
        flash[:notice] = JSON.parse(response.body)
      end

      @membership = Membership.new({
                                     id: update_params[:id].to_i,
                                     name: update_params[:name],
                                     amount: update_params[:amount].to_f,
                                     shares: update_params[:shares].to_i,
                                   })

      render :show
    end
  end

  private

  def update_params
    params.require(:membership).permit(:amount, :shares, :id, :name)
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
