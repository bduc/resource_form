require "test_helper"

class FieldTypesTest < ActiveSupport::TestCase
  test "every partial in the theme has a registered type" do
    partials = Dir[File.expand_path("../app/views/resource_form/daisyui/form/_*.erb", __dir__)]
                 .map { |path| File.basename(path, ".html.erb").delete_prefix("_") }
                 .reject { |name| %w[wrapper unreported_errors].include?(name) }

    registered = ResourceCore.field_types(renderer: :form).values.map(&:partial)

    assert_equal partials.sort, registered.sort,
                 "every field partial needs a registered type, and every type needs a partial"
  end

  test "boolean opts out of the wrapper because it renders its own label" do
    assert_not ResourceCore.field_type(:boolean).wrapper?
    assert ResourceCore.field_type(:text).wrapper?
  end

  test "textarea declares rows as its own option" do
    assert_includes ResourceCore.field_type(:textarea).options, :rows
    assert_not_includes ResourceCore.field_type(:text).options, :rows
  end

  test "the daisyui theme is registered" do
    assert_equal [ :daisyui ], ResourceCore.theme_chain(:daisyui)
  end

  test "name-pattern detection is registered" do
    column = Book.columns.find { |c| c.name == "isbn" }

    assert_equal :password, ResourceCore::Detection.field_type_for(:password, column)
    assert_equal :datetime, ResourceCore::Detection.field_type_for(:published_at, column)
    assert_equal :date,     ResourceCore::Detection.field_type_for(:signed_on, column)
    assert_equal :email,    ResourceCore::Detection.field_type_for(:contact_email, column)
    assert_equal :tel,      ResourceCore::Detection.field_type_for(:mobile, column)
  end

  test "FK and password error rules are registered" do
    assert_equal %i[author_id author], ResourceCore.consumed_error_names(:author_id, {})
    assert_equal %i[password password_confirmation], ResourceCore.consumed_error_names(:password, {})
  end

  test "registering twice is a no-op rather than a duplicate" do
    ResourceForm.register_field_types!
    ResourceForm.register_field_types!

    assert_equal %i[author_id author], ResourceCore.consumed_error_names(:author_id, {})
  end
end
