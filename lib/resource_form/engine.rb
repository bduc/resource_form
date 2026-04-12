module ResourceForm
  class Engine < ::Rails::Engine
    isolate_namespace ResourceForm

    initializer "resource_form.form_helper" do
      ActiveSupport.on_load(:action_view) do
        require "resource_form/helpers/form_helper"
        include ResourceForm::Helpers::FormHelper
      end
    end
  end
end
