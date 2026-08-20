require "test_helper"

class WrapperTest < ActionView::TestCase
  setup { @book = Book.new(title: "Moby Dick") }

  test "the builder wraps a normal field once, around the input" do
    html = render_field(:title, as: :text, label: "Titel")

    # Count the opening tag only. The wrapper's markup also contains
    # `class="fieldset"` and `fieldset-legend`, so counting the bare word and
    # halving it scores 2 for a correct single wrapper.
    assert_equal 1, html.scan("<fieldset").size, "expected exactly one fieldset"
    assert_includes html, "Titel"
    # The input must be inside it. Rendering the wrapper with `partial:`
    # instead of `layout:` yields an empty fieldset, which passes every
    # assertion above.
    assert_match(/<fieldset.*<input[^>]+name="book\[title\]".*<\/fieldset>/m, html)
  end

  test "a wrapper: false type is not wrapped" do
    html = render_field(:out_of_print, as: :boolean)

    assert_not_includes html, "<fieldset"
  end

  test "the partial receives no options local" do
    # _text.html.erb is rewritten to use spec only. If anything still reads
    # `options`, rendering raises rather than silently seeing nil.
    assert_nothing_raised { render_field(:title, as: :text, placeholder: "x") }
  end

  test "call-site options reach the partial through spec" do
    html = render_field(:title, as: :text, placeholder: "Moby Dick")

    assert_includes html, 'placeholder="Moby Dick"'
  end

  test "a type default reaches the partial through spec" do
    html = render_field(:synopsis, as: :textarea)

    assert_includes html, 'rows="4"'
  end

  test "a call-site option beats the type default" do
    html = render_field(:synopsis, as: :textarea, rows: 9)

    assert_includes html, 'rows="9"'
  end

  test "an unregistered type raises naming the type, not a missing template" do
    error = assert_raises(ArgumentError) { render_field(:title, as: :ritch_text) }

    assert_match "ritch_text", error.message
  end

  private

  def render_field(name, **options)
    builder = ResourceForm::FormBuilder.new(:book, @book, view, {})
    builder.field(name, options)
  end
end
