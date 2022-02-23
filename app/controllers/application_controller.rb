class ApplicationController < ActionController::Base
  def index
    if Rails.env.development?
      redirect_to membership_path(id: ENV['EXAMPLE_USER_MAGIC_TOKEN'])
    else
      redirect_to not_found_path
    end
  end
end
