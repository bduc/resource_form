require "test_helper"

class FormBuilderTest < ActiveSupport::TestCase
  def make_builder(object)
    view = ActionView::Base.with_empty_template_cache.with_view_paths([])
    ResourceForm::FormBuilder.new(object.class.name.underscore, object, view, {})
  end

  test "error_for aggregates errors across a field's consumed attribute names" do
    book = Book.new
    book.errors.add(:author, "must exist")

    builder = make_builder(book)
    # :author_id FK field should consume errors on :author association
    consumed = ResourceCore.consumed_error_names(:author_id, {})
    assert_includes consumed, :author
    assert_includes consumed, :author_id
    assert_equal "must exist", builder.send(:error_for, consumed)
  end

  test "explicit consume_errors option adds to the default list" do
    book = Book.new
    book.errors.add(:author, "A")
    book.errors.add(:title, "B")

    builder = make_builder(book)
    consumed = ResourceCore.consumed_error_names(:title, consume_errors: [ :author ])
    assert_includes consumed, :title
    assert_includes consumed, :author
    # to_sentence is locale-dependent ("and" in :en, "en" in :nl), and the host
    # app picks the locale — so assert against it rather than hardcoding English.
    assert_equal [ "B", "A" ].to_sentence, builder.send(:error_for, consumed)
  end

  test "password field defaults to consuming password_confirmation errors" do
    author = Author.new
    author.errors.add(:password_confirmation, "doesn't match")

    make_builder(author)
    consumed = ResourceCore.consumed_error_names(:password, {})
    assert_includes consumed, :password_confirmation
  end

  test "reported_attrs tracks rendered field names" do
    book = Book.new
    builder = make_builder(book)
    assert_equal Set.new, builder.send(:reported_attrs)
  end

  test "unreported_errors returns a placeholder marker" do
    book = Book.new
    builder = make_builder(book)
    marker = builder.unreported_errors
    assert_equal ResourceForm::FormBuilder::UNREPORTED_ERRORS_MARKER, marker
    assert builder.unreported_errors_requested?
  end
end
