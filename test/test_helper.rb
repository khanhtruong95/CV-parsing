ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

ENV["ADMIN_USERNAME"] ||= "admin"
ENV["ADMIN_PASSWORD"] ||= "test-password-123"
ENV["CV_MAX_SIZE_MB"] ||= "25"
ENV["ANTHROPIC_API_KEY"] ||= "test-key-sk-ant-test"

# WebMock: disable net connect except localhost (for system tests with Chrome)
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def self.setup_db
      unless @db_seeded
        Rails.application.load_seed
        @db_seeded = true
      end
    end
  end
end
