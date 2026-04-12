module ResourceForm
  class Configuration
    attr_accessor :theme, :resource_class_suffix

    def initialize
      @theme = :daisyui
      @resource_class_suffix = "Resource"
    end
  end
end
