Rails.application.routes.draw do
  resources :bids
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'application#index'

  get '/mitgliedschaften/:id', to: 'memberships#show', as: 'membership'
  put '/mitgliedschaften/:id', to: 'memberships#edit'
  get '/404', to: 'errors#not_found', as: 'not_found'
  get '/401', to: 'errors#unauthorized', as: 'unauthorized'

end
