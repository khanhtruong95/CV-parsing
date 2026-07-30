module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :authenticate_admin!

    private

    def authenticate_admin!
      expected_user = ENV["ADMIN_USERNAME"].to_s
      expected_password = ENV["ADMIN_PASSWORD"].to_s
      return head :unauthorized if expected_password.blank?

      authenticate_or_request_with_http_basic("DentaMatch Admin") do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(username, expected_user) &
          ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
      end
    end
  end
end
