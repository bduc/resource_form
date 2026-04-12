require "resource_form/version"
require "resource_form/configuration"
require "resource_form/engine"
require "resource_form/base_resource"
require "resource_form/form_builder"

module ResourceForm
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end
  end
end
