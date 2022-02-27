class MembershipsController < ApplicationController
  def show
    flash[:notice] = nil
    response = conn.get('/api/magic_link/login', { token: params[:id] }, headers)

    if response.status != 200
      redirect_to not_found_path
    else
      data = JSON.parse(response.body, symbolize_names: true)

      @membership = Membership.new({
        id: data[:membership][:id],
        name: [data[:name], data[:surname]].join(' '),
        amount: data[:membership][:bids][0][:amount],
      })
    end
  end

  def edit
    body = {
      bid: {
        start_date: "2022-04-01",
        end_date: "2023-03-31",
        membership_id: update_params[:id].to_i,
        amount: update_params[:amount].to_f,
        shares: 2,
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
    })

    render :show
  end

  private

  def update_params
    params.require(:membership).permit(:amount, :id, :name)
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
