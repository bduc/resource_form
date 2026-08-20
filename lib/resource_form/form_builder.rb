require "set"

module ResourceForm
  class FormBuilder < ActionView::Helpers::FormBuilder
    UNREPORTED_ERRORS_MARKER = "<!--RESOURCE_FORM_UNREPORTED_ERRORS-->".freeze

    def field(name, options = {})
      # resource_class.fields only has entries for real columns and
      # associations (ResourceCore::Detection.fields_for). A name that is
      # neither — a virtual attribute like Devise's `password` — falls
      # through to the detector chain with no column, so name-pattern
      # inference (password/email/date/datetime/tel) still applies instead
      # of silently defaulting to :text.
      spec = resource_class.fields[name.to_sym] || { as: ResourceCore::Detection.field_type_for(name, nil) }

      merged = spec.merge(options.deep_symbolize_keys)
      kind = (merged[:as] || :text).to_sym

      type = ResourceCore.field_type(kind)
      unless type
        raise ArgumentError,
              "unknown field type #{kind.inspect} on #{name.inspect}. " \
              "Registered: #{ResourceCore.field_types(renderer: :form).keys.sort.inspect}"
      end

      # Type defaults sit under everything: the resource's spec and the call
      # site both override them.
      merged = type.defaults.merge(merged)

      # Track which attribute names this field consumes errors for.
      consumed = ResourceCore.consumed_error_names(name, merged)
      consumed.each { |n| reported_attrs << n.to_sym }
      error = error_for(consumed)

      locals = { f: self, name: name.to_sym, spec: merged, error: error }
      body = @template.render(partial: partial_path(merged[:partial] || type.partial), locals: locals)

      return body unless type.wrapper?

      # `layout:`, not `partial:` — a partial rendered with `partial:` ignores
      # the block, so `<%= yield %>` in the wrapper would emit nothing and the
      # field would silently vanish inside its own fieldset.
      @template.render(layout: partial_path("wrapper"), locals: locals) { body }
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

      @template.render(
        partial: partial_path("unreported_errors"),
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

    # Walks the theme chain and returns the first path that exists, so a theme
    # only has to supply the partials it actually changes.
    def partial_path(partial)
      chain = ResourceCore.theme_chain(ResourceForm.config.theme)

      # `exists?`'s `partial: true` already prepends the underscore itself
      # (see ActionView::TemplatePath.virtual) — passing "_#{partial}" here
      # would look for a double-underscored file and never find it.
      found = chain.find do |theme|
        @template.lookup_context.exists?(partial.to_s, [ "resource_form/#{theme}/form" ], true)
      end

      unless found
        raise ArgumentError,
              "no partial #{partial.inspect} in theme chain #{chain.inspect}"
      end

      "resource_form/#{found}/form/#{partial}"
    end
  end
end
