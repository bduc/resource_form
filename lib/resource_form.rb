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

    # Human-readable label for a record already selected in a lookup field.
    # `label_method` (from the field spec) takes precedence over the
    # conventional readers in `config.lookup_label_methods`; `to_s` is the
    # last resort so a model that declares none of them still renders.
    def lookup_label(record, label_method: nil)
      return nil if record.nil?

      candidates = [ label_method, *config.lookup_label_methods ].compact
      match = candidates.find do |reader|
        record.respond_to?(reader) && record.public_send(reader).presence
      end

      match ? record.public_send(match).to_s : record.to_s
    end
  end
end
