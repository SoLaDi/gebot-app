class MembershipsController < ApplicationController
  def show
    flash[:notice] = nil
    response = conn.get('/api/magic_link/login', { token: params[:id] }, headers)

    if response.status != 200
      redirect_to not_found_path
    else
      data = JSON.parse(response.body, symbolize_names: true)
      session[:membership_id] = data[:membership][:id]

      bids = data[:membership][:bids]
      current_bid = bids.filter { |bid| bid[:start_date] == "2022-04-01" }.first

      if current_bid
        @membership = Membership.new(
          {
            id: data[:membership][:id],
            name: [data[:name], data[:surname]].join(' '),
            amount: current_bid[:amount],
            shares: current_bid[:shares],
            has_current_bid: true
          })
      else
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
    if !session[:membership_id] || session[:membership_id] == update_params[:id]
      redirect_to unauthorized_path
    else

      body = {
        bid: {
          start_date: "2022-04-01",
          end_date: "2023-03-31",
          membership_id: update_params[:id].to_i,
          amount: update_params[:amount].to_f,
          shares: update_params[:shares].to_i,
        }
      }

      response = conn.post('/api/bids', body.to_json, headers)

      if response.status == 202
        flash[:notice] = 'Gebot aktualisiert!'
      else
        flash[:notice] = JSON.parse(response.body)['base'].join(' ')
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
