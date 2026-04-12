require "set"

module ResourceForm
  class FormBuilder < ActionView::Helpers::FormBuilder
    UNREPORTED_ERRORS_MARKER = "<!--RESOURCE_FORM_UNREPORTED_ERRORS-->".freeze

    def field(name, options = {})
      # Unknown fields get a default spec. This lets f.field :password work
      # on attributes that aren't DB columns (virtual attributes, etc.).
      spec = resource_class.fields[name.to_sym] || infer_spec(name)

      merged = spec.merge(options.deep_symbolize_keys)
      kind = merged[:as] || :text

      # Track which attribute names this field consumes errors for.
      consumed = error_attribute_names(name, merged)
      consumed.each { |n| reported_attrs << n.to_sym }

      partial = merged[:partial] || kind.to_s
      theme = ResourceForm.config.theme

      @template.render(
        partial: "resource_form/#{theme}/form/#{partial}",
        locals: {
          f: self,
          name: name.to_sym,
          spec: merged,
          options: options,
          error: error_for(consumed)
        }
      )
    end

    # Render a placeholder. `resource_form_with` helper replaces the marker
    # with the actual unreported-errors HTML after the form body is captured,
    # so this works at the TOP of a form even though rendered fields are
    # only known at the bottom.
    def unreported_errors
      @unreported_errors_requested = true
      UNREPORTED_ERRORS_MARKER.html_safe
    end

    # Called by the helper AFTER the form body is captured.
    def render_unreported_errors
      return "".html_safe unless object.respond_to?(:errors)

      unreported = object.errors.reject { |err| reported_attrs.include?(err.attribute) }
      return "".html_safe if unreported.empty?

      theme = ResourceForm.config.theme
      @template.render(
        partial: "resource_form/#{theme}/form/unreported_errors",
        locals: { errors: unreported }
      )
    end

    def unreported_errors_requested?
      !!@unreported_errors_requested
    end

    def resource_class
      @resource_class ||= ResourceForm::BaseResource.for(@object.class)
    end

    private

    def reported_attrs
      @reported_attrs ||= Set.new
    end

    # Determine which attribute names a field consumes errors for.
    # Defaults to just the field name. Extras can be added via
    # `consume_errors:` option or spec key, and sensible defaults are
    # applied for known patterns (e.g. FK `foo_id` also consumes `foo`).
    def error_attribute_names(name, spec)
      explicit = Array(spec[:consume_errors]).map(&:to_sym)
      defaults = default_consumed_names(name, spec)
      ([name.to_sym] + defaults + explicit).uniq
    end

    def default_consumed_names(name, spec)
      list = []
      name_str = name.to_s
      # FK column consumes errors on the matching association name
      if name_str.end_with?("_id")
        list << name_str.sub(/_id\z/, "").to_sym
      end
      # Password field consumes confirmation errors
      if name_str == "password"
        list << :password_confirmation
      end
      list
    end

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

    def error_for(names)
      return nil unless object.respond_to?(:errors)
      messages = Array(names).flat_map { |n| object.errors[n] }.compact
      messages.any? ? messages.to_sentence : nil
    end
  end
end
