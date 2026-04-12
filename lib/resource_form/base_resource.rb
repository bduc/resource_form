module ResourceForm
  class BaseResource
    VALID_FIELD_OPTIONS = %i[
      as label hint placeholder prepend append unit
      collection class_name polymorphic values include_blank prompt
      label_method value_method
      partial required readonly disabled width align format
      url rows step accept capture multiple
      show index filter
    ].freeze

    class << self
      attr_writer :model_class_name

      def model_class_name
        @model_class_name ||= name&.sub(/Resource\z/, "")
      end

      def model_class
        @model_class ||= model_class_name&.constantize
      end

      def fields
        initialize_fields unless @fields
        @fields
      end

      def field(name, options = {})
        initialize_fields
        name = name.to_sym
        if options.nil?
          @fields.delete(name)
        else
          options.assert_valid_keys(VALID_FIELD_OPTIONS)
          @fields[name] ||= {}
          @fields[name].merge!(options.deep_symbolize_keys)
        end
      end

      def field!(name, options = {})
        initialize_fields
        name = name.to_sym
        return unless @fields.key?(name)
        if options.nil?
          @fields.delete(name)
        else
          options.assert_valid_keys(VALID_FIELD_OPTIONS)
          @fields[name].merge!(options.deep_symbolize_keys)
        end
      end

      def for(model_class)
        suffix = ResourceForm.config.resource_class_suffix
        if suffix
          explicit = "#{model_class.name}#{suffix}".safe_constantize
          return explicit if explicit && explicit < BaseResource
        end

        @anonymous ||= {}
        @anonymous[model_class.name] ||= Class.new(BaseResource).tap do |klass|
          klass.model_class_name = model_class.name
        end
      end

      private

      def initialize_fields
        return if @fields
        @fields = {}
        detect_fields_from(model_class) if model_class
      end

      def detect_fields_from(ar_model)
        ar_model.columns.each do |col|
          next if %w[id lock_version created_at updated_at].include?(col.name)
          @fields[col.name.to_sym] = { as: column_type_to_field_type(col) }
        end

        ar_model.reflect_on_all_associations.each do |assoc|
          case assoc.macro
          when :belongs_to
            @fields[assoc.name] = {
              as: :lookup_one,
              class_name: assoc.class_name,
              polymorphic: !!assoc.polymorphic?
            }
            @fields.delete(assoc.foreign_key.to_sym)
            @fields.delete(assoc.foreign_type.to_sym) if assoc.polymorphic?
          when :has_many
            @fields[assoc.name] = {
              as: :lookup_many,
              class_name: assoc.class_name
            }
          end
        end
      end

      def column_type_to_field_type(col)
        case col.type
        when :string    then :text
        when :text      then :textarea
        when :integer, :bigint, :decimal, :float then :numeric
        when :boolean   then :boolean
        when :date      then :date
        when :datetime, :timestamp then :datetime
        else :text
        end
      end
    end
  end
end
