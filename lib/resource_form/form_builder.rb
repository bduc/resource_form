module ResourceForm
  class FormBuilder < ActionView::Helpers::FormBuilder
    def field(name, options = {})
      spec = resource_class.fields[name.to_sym]
      raise ArgumentError, "Unknown field :#{name} for #{resource_class.model_class_name}" unless spec

      merged = spec.merge(options.deep_symbolize_keys)
      kind = merged[:as] || :text

      partial = merged[:partial] || kind.to_s
      theme = ResourceForm.config.theme

      @template.render(
        partial: "resource_form/#{theme}/form/#{partial}",
        locals: {
          f: self,
          name: name.to_sym,
          spec: merged,
          options: options,
          error: error_for(name)
        }
      )
    end

    def resource_class
      @resource_class ||= ResourceForm::BaseResource.for(@object.class)
    end

    private

    def error_for(name)
      return nil unless object.respond_to?(:errors)
      errors = object.errors[name]
      errors.any? ? errors.to_sentence : nil
    end
  end
end
