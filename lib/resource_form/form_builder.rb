module ResourceForm
  class FormBuilder < ActionView::Helpers::FormBuilder
    def field(name, options = {})
      # Unknown fields get a default spec. This lets f.field :password work
      # on attributes that aren't DB columns (virtual attributes, etc.).
      spec = resource_class.fields[name.to_sym] || infer_spec(name)

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

    # Infer a reasonable default for attributes not declared in the resource.
    def infer_spec(name)
      case name.to_s
      when /password/      then { as: :password }
      when /_at\z/         then { as: :datetime }
      when /_on\z/, /\Adate_/ then { as: :date }
      when /email/         then { as: :email }
      when /phone|mobile|fax|tel/ then { as: :tel }
      else
        {}
      end
    end

    def error_for(name)
      return nil unless object.respond_to?(:errors)
      errors = object.errors[name]
      errors.any? ? errors.to_sentence : nil
    end
  end
end
