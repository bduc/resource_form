module ResourceForm
  module Helpers
    module FormHelper
      def resource_form_with(**options, &block)
        options[:builder] = ResourceForm::FormBuilder
        form_with(**options, &block)
      end
    end
  end
end
