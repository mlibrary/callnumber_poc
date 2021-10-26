Rails.application.routes.draw do
  get 'callnumber/next'
  get 'callnumber/previous'
  get 'callnumber/first'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
