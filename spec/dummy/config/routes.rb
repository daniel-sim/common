Rails.application.routes.draw do
  mount PR::Common::Engine, at: '/'
end
