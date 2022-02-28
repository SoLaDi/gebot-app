class ErrorsController < ApplicationController
  def not_found
    render text: "Nicht gefunden", status: 404
  end

  def unauthorized
    render text: "unauthorized", status: 401
  end
end
