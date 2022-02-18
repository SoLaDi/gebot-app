class ApplicationController < ActionController::Base
  def index
    redirect_to membership_path(id: SecureRandom.hex(16))
  end
end
