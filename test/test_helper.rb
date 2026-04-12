ENV["RAILS_ENV"] ||= "test"

# Use any Rails app that has resource_form in its Gemfile as the host for tests.
# Defaults to mira_rails; override with RESOURCE_FORM_HOST_APP env var.
host_app = ENV["RESOURCE_FORM_HOST_APP"] || "/home/bdu/mira/mira_rails"
require "#{host_app}/config/environment"
require "rails/test_help"
