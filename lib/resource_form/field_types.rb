module ResourceForm
  # Everything this renderer contributes to the core: its name, its theme, its
  # field types, and the detection and error rules that used to be hardcoded
  # case statements inside FormBuilder.
  #
  # Idempotent, because the engine initializer and the test helper both call it.
  def self.register_field_types!
    return if @registered

    ResourceCore.register_renderer :form, options: %i[
      placeholder required readonly disabled prepend append
    ]

    ResourceCore.register_theme :daisyui

    # One entry per partial in app/views/resource_form/daisyui/form/.
    ResourceCore.register_field_type :text,        renderers: [ :form ]
    ResourceCore.register_field_type :textarea,    renderers: [ :form ], options: %i[rows], defaults: { rows: 4 }
    ResourceCore.register_field_type :email,       renderers: [ :form ]
    ResourceCore.register_field_type :tel,         renderers: [ :form ]
    ResourceCore.register_field_type :password,    renderers: [ :form ], options: %i[autocomplete]
    ResourceCore.register_field_type :numeric,     renderers: [ :form ], options: %i[step min max]
    ResourceCore.register_field_type :date,        renderers: [ :form ]
    ResourceCore.register_field_type :datetime,    renderers: [ :form ]
    ResourceCore.register_field_type :hidden,      renderers: [ :form ], wrapper: false
    ResourceCore.register_field_type :file,        renderers: [ :form ], options: %i[accept capture multiple]
    ResourceCore.register_field_type :select,      renderers: [ :form ],
                                                   options: %i[collection values include_blank prompt label_method value_method]
    ResourceCore.register_field_type :tom_select,  renderers: [ :form ],
                                                   options: %i[collection values include_blank prompt label_method value_method url]
    ResourceCore.register_field_type :lookup_one,  renderers: [ :form ], options: %i[url label_method]
    ResourceCore.register_field_type :lookup_many, renderers: [ :form ], options: %i[url label_method]
    # Renders its own label inside the control, so the shared wrapper would
    # emit a second one.
    ResourceCore.register_field_type :boolean,     renderers: [ :form ], wrapper: false

    # Was FormBuilder#infer_spec. register_detector unshifts, so whichever of
    # these runs last is tried first — registered newest-last so the *latest*
    # rule here wins for a name matching more than one, reproducing the old
    # case statement's top-to-bottom order (password, _at, _on/date_, email,
    # tel all win over anything registered earlier in this list).
    ResourceCore.detect { |name, _column| :tel      if name.to_s.match?(/phone|mobile|fax|tel/) }
    ResourceCore.detect { |name, _column| :email    if name.to_s.include?("email") }
    ResourceCore.detect { |name, _column| :date     if name.to_s.match?(/_on\z|\Adate_/) }
    ResourceCore.detect { |name, _column| :datetime if name.to_s.end_with?("_at") }
    ResourceCore.detect { |name, _column| :password if name.to_s.include?("password") }

    # Was FormBuilder#default_consumed_names.
    ResourceCore.register_error_rule do |name, _spec|
      name.to_s.sub(/_id\z/, "").to_sym if name.to_s.end_with?("_id")
    end
    ResourceCore.register_error_rule do |name, _spec|
      :password_confirmation if name.to_s == "password"
    end

    @registered = true
  end

  # Registration is global state; the test helper resets the registry between
  # tests, so this has to be resettable too.
  def self.reset_registration!
    @registered = false
  end
end
