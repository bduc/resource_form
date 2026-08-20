require "test_helper"

class FormBuilderTest < ActiveSupport::TestCase
  def make_builder(object)
    view = ActionView::Base.with_empty_template_cache.with_view_paths([])
    ResourceForm::FormBuilder.new(object.class.name.underscore, object, view, {})
  end

  # Real view paths (including the engine's own app/views) so the partial
  # actually renders, unlike make_builder's empty lookup context.
  #
  # Built from ApplicationController's own view context class rather than
  # `ActionView::Base.with_empty_template_cache` directly: that call mints a
  # brand new, isolated `compiled_method_container` every time, distinct from
  # the one every controller (and ActionView::TestCase, which other test
  # files use to render fields for real) shares process-wide. Once any
  # partial gets compiled onto one container, `Template#compile!` never
  # recompiles it onto another — so a second, differently-built view hitting
  # the same cached template raises a bare NoMethodError instead of
  # rendering it.
  def make_rendering_builder(object)
    view = ApplicationController.view_context_class.with_view_paths(ApplicationController.view_paths)
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

  test "field infers a type by name pattern for a virtual attribute that is not a column" do
    author = Author.new # Author#password is attr_accessor, not a DB column
    builder = make_rendering_builder(author)

    html = builder.field(:password)

    assert_match(/type="password"/, html)
    assert_no_match(/type="text"/, html)
  end

  test "unreported_errors returns a placeholder marker" do
    book = Book.new
    builder = make_builder(book)
    marker = builder.unreported_errors
    assert_equal ResourceForm::FormBuilder::UNREPORTED_ERRORS_MARKER, marker
    assert builder.unreported_errors_requested?
  end

  # The only other theme assertion in the suite (field_types_test.rb) checks
  # theme_chain(:daisyui) == [:daisyui] — the single-element case, which
  # never exercises the fallback a child theme depends on. This registers a
  # theme with no partials of its own and proves BOTH a field and
  # render_unreported_errors fall back to the parent's, i.e. that
  # render_unreported_errors goes through partial_path like every other
  # partial instead of hardcoding the leaf theme.
  test "a child theme with no partials of its own still resolves fields and unreported_errors through its parent" do
    ResourceCore.register_theme :childless, parent: :daisyui
    original_theme = ResourceForm.config.theme
    ResourceForm.config.theme = :childless

    book = Book.new(title: "Moby Dick")
    book.errors.add(:base, "something is wrong")

    builder = make_rendering_builder(book)
    html = builder.field(:title, as: :text)
    assert_match(/name="book\[title\]"/, html)

    errors_html = builder.render_unreported_errors
    assert_includes errors_html, "something is wrong"
  ensure
    ResourceForm.config.theme = original_theme
  end
end
