module ResourceForm
  class Configuration
    attr_accessor :theme, :resource_class_suffix, :lookup_label_methods

    def initialize
      @theme = :daisyui
      @resource_class_suffix = "Resource"
      # Readers tried, in order, to label an already-selected lookup record.
      # A field can override this with `label_method:`.
      @lookup_label_methods = %i[lookup_label display_name full_name name]
    end
  end
end
