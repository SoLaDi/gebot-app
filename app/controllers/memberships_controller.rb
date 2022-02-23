class MembershipsController < ApplicationController
  def show
    flash[:notice] = nil
    response = conn.get(ENV['SOLADI_API_LOGIN_PATH'], { token: params[:id] }, headers)

    if response.status != 200
      # raise
      redirect_to not_found_path
    else
      data = JSON.parse(response.body, symbolize_names: true)

      @membership = Membership.new({
        name: [data[:name], data[:surname]].join(' '),
        amount: data[:membership][:bids][0][:amount],
      })
    end
  end

  def edit
    if Rails.env.development?
      @membership = Membership.new({ name: 'Max Müller' })
      @membership.attributes = update_params
    else
      # call soladi api to put this membership
    end

    flash[:notice] = 'Gebot aktualisiert!'
    render :show
  end

  private

  def update_params
    params.require(:membership).permit(:amount)
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
