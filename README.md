# resource_form

Auto-detecting Rails form builder with partial templates per CSS framework.

It is a renderer built on [`resource_core`](https://github.com/bduc/resource_core),
which owns the field spec and every extension point (field types, themes,
detection, error routing, value formatting) shared by every renderer.
Anything not specific to *forms* — `ApplicationResource`, `register_theme`,
`register_namespace`, `detect`, and so on — is documented there, not here.

## Features

- **Auto-detection**: Field types derived from ActiveRecord schema
- **Partial-based templates**: One partial per field type, per theme
- **Implicit resource classes**: No empty boilerplate — declare a `*Resource` class only when overriding
- **Custom fields**: A registration (`ResourceCore.register_field_type`) plus a partial — see [Custom field types](#custom-field-types)
- **Per-field decorations**: Prepend, append, hints, errors handled by a single wrapper partial
- **Error consumption**: FK fields automatically consume errors from their association name; `consume_errors:` option handles other cases
- **Unreported errors alert**: `f.unreported_errors` displays errors on attributes not rendered as fields (hidden_field errors no longer silently fail)
- **Lookup labels**: a selected record labels itself via a `lookup_label` convention, so the preselected option matches what the AJAX endpoint returned

## Usage

```erb
<%= resource_form_with(model: @book) do |f| %>
  <%= f.field :title %>                 <%# auto-detected as :text %>
  <%= f.field :published_on %>          <%# auto-detected as :date %>
  <%= f.field :author %>                <%# auto-detected as :lookup_one %>
  <%= f.field :metadata, as: :textarea %>
  <%= f.submit %>
<% end %>
```

## Overriding field types per model

```ruby
# app/resources/book_resource.rb
class BookResource < ApplicationResource
  field :price, append: "€"
  field :synopsis, as: :textarea, hint: "Shown on the book's detail page"
end
```

`ApplicationResource` is your app's own subclass of `ResourceCore::BaseResource`
(see resource_core's README) — declared once, the way `ApplicationRecord`
works. A `*Resource` class is only needed when you want to override
auto-detection; for models with no overrides, an anonymous resource is
created on demand.

## Custom field types

A field type is a registration plus a partial.

```ruby
# config/initializers/resource_form.rb
ResourceCore.register_field_type :rich_text,
  renderers: [ :form ],
  options:   %i[toolbar],
  defaults:  { rows: 6 }
```

```erb
<%# app/views/resource_form/daisyui/form/_rich_text.html.erb
    Locals: f, name, spec, error — nothing else.
    The builder has already merged the resource's spec, the call site's
    options and the type's defaults into `spec`, and renders the wrapper
    around whatever you return unless the type declared `wrapper: false`. %>
<%= f.text_area name, rows: spec[:rows], data: { toolbar: spec[:toolbar] } %>
```

An unregistered `as:` raises at render with the list of registered types, rather
than an `ActionView::MissingTemplate` naming a path you did not write.

## Configuration

```ruby
# config/initializers/resource_form.rb
ResourceForm.configure do |c|
  c.theme = :daisyui   # partial subfolder to use; falls back to ResourceCore.config.theme if unset
end
```

Everything else — `resource_class_suffix`, `lookup_label_methods`,
`base_class` — is `ResourceCore.config`, shared by every renderer:

```ruby
ResourceCore.configure do |c|
  c.resource_class_suffix = "Resource"
  c.lookup_label_methods = %i[lookup_label display_name full_name name]
end
```

## Themes

- `daisyui` (v1) — Tailwind CSS + DaisyUI 5
- Add your own by creating `app/views/resource_form/<theme_name>/form/_<input_type>.html.erb` and registering it with `ResourceCore.register_theme` (see resource_core's README) — a theme with a `parent:` only needs the partials that differ

## Overriding partials in the consuming app

Rails view resolution lets you override gem partials by providing a file at the same path in your app:

```
app/views/resource_form/daisyui/form/_select.html.erb         # overrides gem default
app/views/resource_form/daisyui/form/books/_select.html.erb   # overrides only for books
```

## Error handling

Each field's wrapper displays inline errors from `object.errors[name]`. A few behaviors make this more useful than plain Rails:

**Automatic error consumption.** A FK field like `:author_id` also consumes errors on the `:author` association. A `:password` field consumes `:password_confirmation` errors. So a validation like `validates :author, presence: true` surfaces on the `author_id` select without needing any config. These two rules are registered with `ResourceCore.register_error_rule` — see resource_core's README to add more.

**Explicit `consume_errors:`** when a field is responsible for errors on other attribute names:

```erb
<%= f.field :cover, consume_errors: [:cover_content_type, :cover_size] %>
```

Or declare it on the resource:

```ruby
field :cover, as: :file, consume_errors: [:cover_content_type, :cover_size]
```

**Unreported-errors alert.** Validation errors on attributes that no `f.field` rendered would otherwise silently fail (the form re-renders with no visible error). Place `f.unreported_errors` at the top of the form and any such errors appear in an alert:

```erb
<%= resource_form_with(model: @book) do |f| %>
  <%= f.unreported_errors %>   <%# Shows errors on hidden fields or undisplayed attributes %>
  <%= f.field :title %>
  <%= f.field :author %>
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
- `show:`, `index:`, `filter:` — namespaced keys reserved for future non-form view modes (registered with `ResourceCore.register_namespace`; ignored by FormBuilder)

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
class Author < ApplicationRecord
  def lookup_label
    "#{name} (##{id})"
  end
end
```

Override the chain globally with:

```ruby
ResourceCore.configure { |c| c.lookup_label_methods = %i[caption name] }
```

## Multi-view (future)

The spec's `show:`, `index:`, and `filter:` namespaced keys are reserved for future renderers that will read the same resource class and produce detail/table/filter views. v1 only implements forms; partials are organized under `form/` subfolder so other modes can coexist without restructuring.
