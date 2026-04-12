module ResourceForm
  module Helpers
    module FormHelper
      def resource_form_with(**options, &block)
        options[:builder] = ResourceForm::FormBuilder

        captured_builder = nil
        wrapped = ->(f) {
          captured_builder = f
          block.call(f)
        }

        html = form_with(**options, &wrapped)

        if captured_builder&.unreported_errors_requested?
          errors_html = captured_builder.render_unreported_errors
          html = html.to_s.sub(ResourceForm::FormBuilder::UNREPORTED_ERRORS_MARKER, errors_html).html_safe
        end

        html
      end
    end
  end
end
