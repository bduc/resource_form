module ResourceForm
  class Configuration
    attr_writer :theme

    # Falls back to the core's theme, so an app that sets one setting gets
    # consistent behaviour from every renderer, and can still override per
    # renderer when it needs to.
    def theme
      @theme || ResourceCore.config.theme
    end
  end
end
