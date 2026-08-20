require "resource_core"
require "resource_form/version"
require "resource_form/configuration"
require "resource_form/engine"
require "resource_form/field_types"
require "resource_form/form_builder"

module ResourceForm
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    # Kept as a delegation rather than deleted: the lookup partials call it, and
    # it reads better in a view than the core's full name.
    def lookup_label(record, label_method: nil)
      ResourceCore.lookup_label(record, label_method: label_method)
    end
  end
end
