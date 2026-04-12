# resource_form

Auto-detecting Rails form builder with partial templates per CSS framework.

## Features

- **Auto-detection**: Field types derived from ActiveRecord schema
- **Partial-based templates**: One partial per field type, per theme
- **Implicit resource classes**: No empty boilerplate — declare a `*Resource` class only when overriding
- **Easy custom fields**: Drop a partial into `app/views/resource_form/<theme>/form/_my_field.html.erb`
- **Per-field decorations**: Prepend, append, hints, errors handled by a single wrapper partial

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

## Field spec options

- `as:` — input type (`:text`, `:textarea`, `:select`, `:date`, `:boolean`, `:lookup_one`, etc.)
- `label:` — override the label text
- `hint:` — helper text shown below the field
- `placeholder:` — input placeholder
- `prepend:` / `append:` — text decorations before/after the input (rendered as DaisyUI `join`)
- `collection:` / `values:` — for select fields
- `class_name:` — for lookup_one / lookup_many
- `url:` — tom-select AJAX endpoint for lookups
- `required:`, `readonly:`, `disabled:`
- `partial:` — explicitly pick a custom partial name
- `show:`, `index:`, `filter:` — reserved for future non-form view modes (ignored by FormBuilder)

## Multi-view (future)

The spec's `show:`, `index:`, and `filter:` namespaced keys are reserved for future renderers that will read the same resource class and produce detail/table/filter views. v1 only implements forms; partials are organized under `form/` subfolder so other modes can coexist without restructuring.
