module Admin
  class BaseController < ActionController::Base
    before_action :authenticate_admin!
  end
end
