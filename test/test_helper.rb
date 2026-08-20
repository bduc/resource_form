ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("dummy/db/migrate", __dir__) ]
require "rails/test_help"

class ActiveSupport::TestCase
  # Registration is global; without this a type registered by one test is still
  # there for the next.
  teardown { ResourceCore::Registry.reset!; ResourceForm.reset_registration! }
  setup { ResourceForm.register_field_types! }
end
