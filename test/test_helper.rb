ENV["RAILS_ENV"] ||= "test"

# Use any Rails app that has resource_form in its Gemfile as the host for tests.
# Defaults to the sibling mira_rails checkout (the mirror of the `path:` entry in
# its Gemfile), so the pair keeps working wherever the tree is checked out.
# Override with RESOURCE_FORM_HOST_APP.
host_app = ENV["RESOURCE_FORM_HOST_APP"] || File.expand_path("../../mira/mira_rails", __dir__)

unless File.exist?("#{host_app}/config/environment.rb")
  abort <<~MSG
    Host app not found at #{host_app}.
    Point RESOURCE_FORM_HOST_APP at a Rails app that has resource_form in its Gemfile:

      RESOURCE_FORM_HOST_APP=/path/to/app ruby -Itest test/lookup_label_test.rb
  MSG
end

require "#{host_app}/config/environment"
require "rails/test_help"
