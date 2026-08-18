# resource_form

Auto-detecting Rails form builder with partial templates per CSS framework.

## Features

- **Auto-detection**: Field types derived from ActiveRecord schema
- **Partial-based templates**: One partial per field type, per theme
- **Implicit resource classes**: No empty boilerplate — declare a `*Resource` class only when overriding
- **Easy custom fields**: Drop a partial into `app/views/resource_form/<theme>/form/_my_field.html.erb`
- **Per-field decorations**: Prepend, append, hints, errors handled by a single wrapper partial
- **Error consumption**: FK fields automatically consume errors from their association name; `consume_errors:` option handles other cases
- **Unreported errors alert**: `f.unreported_errors` displays errors on attributes not rendered as fields (hidden_field errors no longer silently fail)
- **Lookup labels**: a selected record labels itself via a `lookup_label` convention, so the preselected option matches what the AJAX endpoint returned

## Usage

```erb
<%= resource_form_with(model: @member) do |f| %>
  <%= f.field :name %>                 <%# auto-detected as :text %>
  <%= f.field :birth_date %>           <%# auto-detected as :date %>
  <%= f.field :province %>             <%# auto-detected as :lookup_one %>
  <%= f.field :notes, as: :textarea %>
  <%= f.submit %>
<% end %>
```

## Overriding field types per model

```ruby
# app/resources/member_resource.rb
class MemberResource < ResourceForm::BaseResource
  field :membership_fee, append: "€"
  field :status, as: :select, values: %w[active inactive]
end
```

A `*Resource` class is only needed when you want to override auto-detection. For models with no overrides, an anonymous resource is created on demand.

## Custom field types

Drop a partial at `app/views/resource_form/<theme>/form/_google_map.html.erb`, then use:

```erb
<%= f.field :location, as: :google_map %>
```

The partial receives `f`, `name`, `spec`, `options`, and `error` as locals. Call the shared wrapper to get fieldset/legend/error/hint/prepend/append chrome:

```erb
<%= render "resource_form/<theme>/form/wrapper", f: f, name: name, spec: spec, options: options, error: error do %>
  <!-- your input HTML here -->
<% end %>
```

## Configuration

```ruby
# config/initializers/resource_form.rb
ResourceForm.configure do |c|
  c.theme = :daisyui             # partial subfolder to use
  c.resource_class_suffix = "Resource"
  c.lookup_label_methods = %i[lookup_label display_name full_name name]
end
```

## Themes

- `daisyui` (v1) — Tailwind CSS + DaisyUI 5
- Add your own by creating `app/views/resource_form/<theme_name>/form/_<input_type>.html.erb`

## Overriding partials in the consuming app

Rails view resolution lets you override gem partials by providing a file at the same path in your app:

```
app/views/resource_form/daisyui/form/_select.html.erb           # overrides gem default
app/views/resource_form/daisyui/form/members/_select.html.erb   # overrides only for members
```

## Error handling

Each field's wrapper displays inline errors from `object.errors[name]`. A few behaviors make this more useful than plain Rails:

**Automatic error consumption.** A FK field like `:province_id` also consumes errors on the `:province` association. A `:password` field consumes `:password_confirmation` errors. So a validation like `validates :province, presence: true` surfaces on the `province_id` select without needing any config.

**Explicit `consume_errors:`** when a field is responsible for errors on other attribute names:

```erb
<%= f.field :photo, consume_errors: [:photo_content_type, :photo_size] %>
```

Or declare it on the resource:

```ruby
field :photo, as: :file, consume_errors: [:photo_content_type, :photo_size]
```

**Unreported-errors alert.** Validation errors on attributes that no `f.field` rendered would otherwise silently fail (the form re-renders with no visible error). Place `f.unreported_errors` at the top of the form and any such errors appear in an alert:

```erb
<%= resource_form_with(model: @member) do |f| %>
  <%= f.unreported_errors %>   <%# Shows errors on hidden fields or undisplayed attributes %>
  <%= f.field :name %>
  <%= f.field :email %>
  <%= f.submit %>
<% end %>
```

The helper is resolved after the form body renders, so it works even at the top of the form — the marker is swapped for the final HTML once all `f.field` calls have registered which attributes they "reported".

## Field spec options

- `as:` — input type (`:text`, `:textarea`, `:select`, `:date`, `:boolean`, `:lookup_one`, etc.)
- `label:` — override the label text
- `hint:` — helper text shown below the field
- `placeholder:` — input placeholder
- `prepend:` / `append:` — text decorations before/after the input (rendered as DaisyUI `join`)
- `collection:` / `values:` — for select fields
- `class_name:` — for lookup_one / lookup_many
- `url:` — tom-select AJAX endpoint for lookups
- `label_method:` — reader used to label the option (select) or the already-selected record (lookups)
- `required:`, `readonly:`, `disabled:`
- `partial:` — explicitly pick a custom partial name
- `show:`, `index:`, `filter:` — reserved for future non-form view modes (ignored by FormBuilder)

## Labelling selected lookup records

A `lookup_one` / `lookup_many` field renders its already-selected record as a preselected
`<option>`, so it needs a label without hitting the AJAX endpoint. The label is resolved as:

1. the field's `label_method:`, if it returns a present value
2. the first present reader in `config.lookup_label_methods` — by default
   `:lookup_label`, `:display_name`, `:full_name`, `:name`
3. `to_s`

Defining `lookup_label` on a model is the zero-config route, and lets the model be the single
source of truth for its label — have the AJAX endpoint return the same string so the option text
does not change between picking a record and re-opening the form:

```ruby
class Member < ApplicationRecord
  def lookup_label
    "#{last_name} #{first_name} (##{id})"
  end
end
```

Override the chain globally with:

```ruby
ResourceForm.configure { |config| config.lookup_label_methods = %i[caption name] }
```

## Multi-view (future)

The spec's `show:`, `index:`, and `filter:` namespaced keys are reserved for future renderers that will read the same resource class and produce detail/table/filter views. v1 only implements forms; partials are organized under `form/` subfolder so other modes can coexist without restructuring.
