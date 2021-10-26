Rails.application.routes.draw do
  get '/', to: redirect('callnumber')
  get 'callnumber/', to: 'callnumber#index'
  get 'callnumber/next'
  get 'callnumber/previous'
  get 'callnumber/first'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
