require "test_helper"

class FormBuilderTest < ActiveSupport::TestCase
  def make_builder(object)
    view = ActionView::Base.with_empty_template_cache.with_view_paths([])
    ResourceForm::FormBuilder.new(object.class.name.underscore, object, view, {})
  end

  test "error_for aggregates errors across a field's consumed attribute names" do
    fed = Federation.new
    fed.errors.add(:province, "must exist")

    builder = make_builder(fed)
    # :province_id FK field should consume errors on :province association
    consumed = builder.send(:error_attribute_names, :province_id, {})
    assert_includes consumed, :province
    assert_includes consumed, :province_id
    assert_equal "must exist", builder.send(:error_for, consumed)
  end

  test "explicit consume_errors option adds to the default list" do
    fed = Federation.new
    fed.errors.add(:province, "A")
    fed.errors.add(:name, "B")

    builder = make_builder(fed)
    consumed = builder.send(:error_attribute_names, :name, consume_errors: [:province])
    assert_includes consumed, :name
    assert_includes consumed, :province
    assert_equal "B and A", builder.send(:error_for, consumed)
  end

  test "password field defaults to consuming password_confirmation errors" do
    user = User.new
    user.errors.add(:password_confirmation, "doesn't match")

    builder = make_builder(user)
    consumed = builder.send(:error_attribute_names, :password, {})
    assert_includes consumed, :password_confirmation
  end

  test "reported_attrs tracks rendered field names" do
    fed = Federation.new
    builder = make_builder(fed)
    assert_equal Set.new, builder.send(:reported_attrs)
  end

  test "unreported_errors returns a placeholder marker" do
    fed = Federation.new
    builder = make_builder(fed)
    marker = builder.unreported_errors
    assert_equal ResourceForm::FormBuilder::UNREPORTED_ERRORS_MARKER, marker
    assert builder.unreported_errors_requested?
  end
end
