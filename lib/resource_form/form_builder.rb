require "set"

module ResourceForm
  class FormBuilder < ActionView::Helpers::FormBuilder
    UNREPORTED_ERRORS_MARKER = "<!--RESOURCE_FORM_UNREPORTED_ERRORS-->".freeze

    def field(name, options = {})
      spec = resource_class.fields[name.to_sym] || {}

      merged = spec.merge(options.deep_symbolize_keys)
      kind = merged[:as] || :text

      # Track which attribute names this field consumes errors for.
      consumed = ResourceCore.consumed_error_names(name, merged)
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
      @resource_class ||= ResourceCore.resolve(@object.class)
    end

    private

    def reported_attrs
      @reported_attrs ||= Set.new
    end

    def error_for(names)
      return nil unless object.respond_to?(:errors)
      messages = Array(names).flat_map { |n| object.errors[n] }.compact
      messages.any? ? messages.to_sentence : nil
    end
  end
end
