# mep_insight → resource_form Migration Plan

**Status:** Planning (deferred). The user has higher-priority work first. This document captures what needs to happen when the migration is taken up.

**Scope:** Migrate 53 form partials across `insight_core` engine + `insight_lambrechts` and `mep_tereos` apps from `BootstrapForm + ResourceFormBuilder` to the `resource_form` engine with a new `coreui` theme.

**Path:** Gemfile will reference `../../resource_form` from `/home/bdu/mep_insight/mep_insight`.

---

## Executive summary

mep_insight's forms are driven by a `BaseResource` + `ResourceFormBuilder` pattern that's conceptually identical to what we've built in resource_form — but richer in features (attr_json, lookup caching, display helpers, component rendering) and coupled to Bootstrap/CoreUI markup via the `bootstrap_form` gem.

**Direct drop-in replacement is not possible.** The work breaks into:
1. Bringing `resource_form`'s `BaseResource` up to feature parity with mep_insight's (attr_json, lookup_data, select_data, component hooks).
2. Building a `coreui` theme — one partial per input type — matching CoreUI 5 conventions (CSS vars, `form-control`, `form-select`, `form-label`, `form-check`, `invalid-feedback`, etc.).
3. Porting the autocomplete Stimulus controller (tom-select wrapper with polymorphic lookups, optgroup columns, virtual scroll) since the current resource_form controller is too basic.
4. Creating CoreUI partials for specialty field types: `icon_select`, `richtext`, `color`, `attachments`, `static_control`.
5. Migrating the 53 form partials, resource classes, and any form-related tests.

**Estimated effort:** 3–5 focused days for engine-side work, plus 2–3 days of incremental form migration.

---

## Phase 1 — Engine enhancements (prerequisite, 2 days)

Do these before touching mep_insight. Work happens in `/home/bdu/resource_form`. Tests run against mira_rails host.

### 1.1 `attr_json` auto-detection in `BaseResource`

Port lines 118-136 of `mep_insight/engines/insight_core/app/resources/base_resource.rb`. When a model responds to `attr_json_registry`, iterate its JSON attributes and auto-detect their types via `ActiveModel::Type::Boolean`, `::Integer`, `::Float`, `::BigInteger`, `::Decimal`, `::Time`, `::DateTime`, `::Date`, `::String`.

**Files:**
- `lib/resource_form/base_resource.rb` — extend `detect_fields_from(ar_model)`
- `test/base_resource_test.rb` — add a test model with `attr_json` to a test fixture (or skip detection gracefully when the method doesn't exist, which is the common case)

### 1.2 `lookup_data(name, selected)` method

Port lines 289-328. Returns `{options:, url:}` pair: if the lookup class has ≤ N active records (configurable, default 20) return preloaded `options`; otherwise return the query URL. Used by the lookup_one/lookup_many partials to decide preload vs AJAX.

**Files:**
- `lib/resource_form/base_resource.rb`
- `lib/resource_form/configuration.rb` — add `preload_lookup_threshold` (default 20)

### 1.3 `select_data(name)` method

Port lines 330-337. Returns a simple `[[label, value], ...]` array for a belongs_to field when the user wants a plain select (not tom-select).

### 1.4 Field spec options

Extend `VALID_FIELD_OPTIONS` to include: `component`, `format`, `link_to`, `link_ref`, `children_of`, `allowed_context_types`, `polymorphic`, `companion_field`, `companion_placeholder`, `default_icon`, `placeholder_icon`.

### 1.5 `FormBuilder` component / format / link_to hooks

When `spec[:component]` is set, FormBuilder renders the ViewComponent (`@template.render(component.new(...))`) instead of a partial.

**Files:**
- `lib/resource_form/form_builder.rb`

### 1.6 Helper method for autocomplete item shape

Add a module (or instance method on BaseResource) that can produce `{ value:, text:, description:, icon:, optgroup: }` hashes from objects responding to `to_autocomplete_item` (used by mep_insight models). Fall back to `{ value: obj.id, text: obj.to_s }` when the method isn't available — so vanilla Rails models still work.

---

## Phase 2 — CoreUI theme (2 days)

Every partial lives at `app/views/resource_form/coreui/form/_<type>.html.erb`. Wrapper is the common chrome; type-specific partials render just the input.

### 2.1 Wrapper

```erb
<!-- app/views/resource_form/coreui/form/_wrapper.html.erb -->
<div class="form-group mb-3 <%= 'has-error' if error %>">
  <% unless options[:label] == false %>
    <label class="form-label" for="<%= f.field_id(name) %>">
      <%= options[:label] || spec[:label] || f.object.class.human_attribute_name(name) %>
    </label>
  <% end %>
  <% if spec[:prepend] || spec[:append] %>
    <div class="input-group">
      <% if spec[:prepend] %><span class="input-group-text"><%= spec[:prepend] %></span><% end %>
      <%= yield %>
      <% if spec[:append] %><span class="input-group-text"><%= spec[:append] %></span><% end %>
    </div>
  <% else %>
    <%= yield %>
  <% end %>
  <% if error %><div class="invalid-feedback d-block"><%= error %></div><% end %>
  <% if spec[:hint] %><div class="form-text"><%= spec[:hint] %></div><% end %>
</div>
```

### 2.2 Standard partials (port shape from daisyui/, swap classes)

| Partial | CoreUI input class |
|---------|-------------------|
| `_text.html.erb` | `form-control` |
| `_textarea.html.erb` | `form-control` |
| `_email.html.erb` | `form-control` |
| `_tel.html.erb` | `form-control` |
| `_numeric.html.erb` | `form-control` |
| `_date.html.erb` | `form-control` |
| `_datetime.html.erb` | `form-control` |
| `_password.html.erb` | `form-control` |
| `_file.html.erb` | `form-control` |
| `_select.html.erb` | `form-select` |
| `_boolean.html.erb` | `form-check-input` inside `<div class="form-check form-switch">` |
| `_hidden.html.erb` | no class |

Error class: `is-invalid`. Append `is-invalid` to the input class when `error` is non-nil.

### 2.3 Specialty partials

- `_lookup_one.html.erb` / `_lookup_many.html.erb`: `<input type="text" class="form-control" data-controller="form--autocomplete" ...>` — NOT a `<select>`. Matches mep_insight's pattern.
- `_static_control.html.erb`: read-only field, `class="form-control-plaintext"` with `tabindex="-1"`.
- `_richtext.html.erb`: `<textarea class="form-control" data-controller="formeditor" data-formeditor-tools-value="<%= spec[:toolset] %>">`.
- `_color.html.erb`: `<div data-controller="color-picker">` wrapping `<div data-color-picker-target="picker">` + hidden input.
- `_icon_select.html.erb`: `<div data-controller="form--icon-select">` with dropdown button + icon + companion text field (port exactly from ResourceFormBuilder lines 325-398).
- `_attachments.html.erb`: renders a placeholder `<div data-controller="attachments">` — the actual component is provided by mep_insight's `Attachments::EditAllComponent` which stays in the app, not in resource_form.
- `_radio_inline.html.erb`: inline radio buttons (port from `field_as_radio_inline`).
- `_checkboxes.html.erb`: multi-checkbox (port from `field_as_checkboxes`).

---

## Phase 3 — Autocomplete Stimulus controller (1 day)

The current `tom_select_controller.js` in resource_form is a minimal wrapper. mep_insight's `form--autocomplete_controller.js` is sophisticated: polymorphic search, optgroup columns, virtual scroll, preloaded mode, children-of scoping.

**Decision:** Copy mep_insight's controller into resource_form and rename to `form--autocomplete`. Keep it themeable-agnostic (no CoreUI-specific classes in the controller).

**Files to copy:**
- `engines/insight_core/app/javascript/controllers/form/autocomplete_controller.js` → `app/javascript/resource_form/controllers/autocomplete_controller.js`
- Related CSS (`autocomplete_controller.scss`) → `app/assets/stylesheets/resource_form/autocomplete.css`

**Data attribute contract** (preserved as-is from mep_insight):
- `data-form--autocomplete-url-value` — query endpoint
- `data-form--autocomplete-multiple-value` — boolean
- `data-form--autocomplete-selected-value` — JSON of pre-selected items
- `data-form--autocomplete-placeholder-value` — placeholder
- `data-form--autocomplete-min-chars-value` — min chars to trigger
- `data-form--autocomplete-preloaded-options-value` — JSON for small datasets
- `data-form--autocomplete-polymorphic-value` / `-allowed-types-value` — polymorphic search
- `data-form--autocomplete-children-of-value` — scope results

**Response JSON contract** (enforced on the app side):
```json
{
  "results": [{ "value": "...", "text": "...", "description": "...", "icon": "...", "optgroup": "..." }],
  "optgroups": [{ "value": "...", "label": "...", "icon": "..." }],
  "pagination": { "more": false }
}
```

**Rails engine integration:** Ship the controller as a static asset via the engine's `app/javascript/`. Document in README how to import it in the host app's `application.js`.

---

## Phase 4 — Optional FormComponent ViewComponents

**Skip for v1 of mep_insight migration.** The existing `Resources::FormComponent` and `Resources::ModalFormComponent` wrap the form in a modal shell with header + body + footer. For resource_form, I recommend leaving modal structure in the consuming app (either plain partials or app-side ViewComponents) and having `resource_form` only provide the field rendering.

If needed later, we can add `ResourceForm::FormComponent` as an opt-in helper, but do NOT block the migration on it.

---

## Phase 5 — Host-app contract (models & routes)

mep_insight models implement a specific contract that the new autocomplete controller will expect. These stay in the app, not in resource_form:

- `Model.active` scope
- `Model.ordered` scope
- `Model.lookup_query(term)` scope (search by term)
- `instance.to_autocomplete_item` → `{ value:, text:, icon:, description: }`
- `instance.to_rid` → globally unique ID string
- `ApplicationRecord.rid_class(rid_type)` → resolver
- `ApplicationRecord.find_by_rid(rid_string)` → lookup

**Lookup endpoints** stay in mep_insight's `LookupsController` — resource_form does NOT ship routes. The docs will describe the expected endpoint shape.

---

## Phase 6 — Incremental form migration (2-3 days)

Migrate forms in order of dependency / risk:

1. **Leaves first:** Simple forms with no custom field types — `roles`, `teams`, `groups`, `notes`, `remarks`. (≈ 5 forms)
2. **Mid complexity:** Forms with standard lookups — `people`, `companies`, `users`. (≈ 10 forms)
3. **Complex:** Forms with icon_select, richtext, attachments — `issues`, `contact_methods`, `cfesd_procedures`. (≈ 15 forms)
4. **Polymorphic / device specific:** The `mep_tereos` device/equipment/worklist forms with context_tree scoping. (≈ 25 forms)

Per form:
- Create an explicit `XxxResource < ResourceForm::BaseResource` class only if the auto-detection needs overrides (should cover ~70% implicitly)
- Replace `bootstrap_form_with(..., builder: ResourceFormBuilder)` with `resource_form_with(model:)` — field call sites stay `f.field :name` since mep_insight already uses that method name

---

## What stays in mep_insight (not ported to resource_form)

- `context_tree_links` and `context_tree_objects` scoping — domain-specific to mep_insight's hierarchical data
- `remarks`, `remarks_counters`, `audits` system fields — domain-specific
- `Attachments::EditAllComponent` — lives in mep_insight, referenced by spec
- RID (Resource ID) system — lives in mep_insight's `ApplicationRecord`
- `LookupsController` with all its query logic

`resource_form` stays focused on form rendering + auto-detection + theming. It does not own the domain model.

---

## Risks and mitigations

| Risk | Mitigation |
|------|-----------|
| CoreUI class churn between versions (4 vs 5) | Target CoreUI 5 classes (what mep_insight uses); test one form first |
| `bootstrap_form` gem's validation integration differs from plain form_with | Port validation-class logic into the wrapper partial; verify `:is-invalid` shows on errors |
| `form--icon-select` controller is complex; risk of regression | Copy verbatim, add a Stimulus test or visual smoke test |
| Many forms have conditional field visibility (`if can?(:reparent)`) | Verbatim preservation; the pattern works in resource_form because call sites are `<%= f.field :x if cond %>` |
| nested `fields_for` with sub-models | Test with a sub-resource partial (see Description on Issue) |

---

## Open questions to resolve before execution

1. Should resource_form ship a CoreUI theme at all, or should the theme live inside mep_insight and resource_form stay CSS-framework-neutral? My recommendation: **ship coreui as a second theme in resource_form** — it makes mep_insight simpler and validates the multi-theme design.
2. Same question for `form--autocomplete_controller.js` — does it ship in the engine or the host app? Recommendation: **ship in the engine** (as an importable Stimulus controller), so all coreui-themed apps get it for free.
3. `Attachments::EditAllComponent` and rich text editors — stay in the app, partial in the engine just renders the wrapper markup.
4. Do we need ViewComponents (`FormComponent`, `ModalFormComponent`) in resource_form, or are plain partials enough? Recommendation: **plain partials for v1**, add components later if a real need arises.

---

## Success criteria

- [ ] All 53 mep_insight forms render and function identically to the current BootstrapForm-based implementation
- [ ] `bootstrap_form` gem can be removed from mep_insight's Gemfile
- [ ] `ResourceFormBuilder` and `BaseResource` in `insight_core` are either deleted or reduced to domain-specific extensions
- [ ] resource_form's `coreui` theme is documented in the engine README
- [ ] At least one end-to-end test exercises a lookup_one field against the live autocomplete endpoint
