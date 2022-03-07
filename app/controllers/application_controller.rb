class ApplicationController < ActionController::Base
  add_flash_types :info, :error, :warning, :success

  def index
    if Rails.env.development?
      redirect_to membership_path(id: ENV['EXAMPLE_USER_MAGIC_TOKEN'])
    else
      redirect_to not_found_path
    end
  end
end
