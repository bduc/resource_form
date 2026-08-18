require "test_helper"

class LookupLabelTest < ActiveSupport::TestCase
  # Build an anonymous record exposing only the given methods, so these tests
  # describe the engine's resolution rules rather than any host-app model.
  def record(**readers)
    Class.new do
      readers.each { |name, value| define_method(name) { value } }

      def to_s
        "#<Anonymous>"
      end
    end.new
  end

  test "an explicit label_method wins over the convention chain" do
    obj = record(lookup_label: "Convention", code: "Explicit")
    assert_equal "Explicit", ResourceForm.lookup_label(obj, label_method: :code)
  end

  test "an explicit label_method that returns blank falls back to the chain" do
    obj = record(name: "Fallback", code: "")
    assert_equal "Fallback", ResourceForm.lookup_label(obj, label_method: :code)
  end

  test "lookup_label is preferred over the other conventional readers" do
    obj = record(lookup_label: "Peeters Jan (#7)", display_name: "Jan P.", name: "Jan")
    assert_equal "Peeters Jan (#7)", ResourceForm.lookup_label(obj)
  end

  test "display_name and full_name are used when lookup_label is absent" do
    assert_equal "Jan P.", ResourceForm.lookup_label(record(display_name: "Jan P.", name: "Jan"))
    assert_equal "Jan Peeters", ResourceForm.lookup_label(record(full_name: "Jan Peeters", name: "Jan"))
  end

  test "name is used when no richer reader is defined" do
    assert_equal "Antwerpen", ResourceForm.lookup_label(record(name: "Antwerpen"))
  end

  test "blank readers are skipped in favour of later ones" do
    assert_equal "Antwerpen", ResourceForm.lookup_label(record(lookup_label: nil, display_name: "  ", name: "Antwerpen"))
  end

  test "to_s is the last resort when nothing in the chain matches" do
    assert_equal "#<Anonymous>", ResourceForm.lookup_label(record(id: 1))
  end

  test "a nil record has no label" do
    assert_nil ResourceForm.lookup_label(nil)
  end

  test "the convention chain is configurable" do
    original = ResourceForm.config.lookup_label_methods
    ResourceForm.config.lookup_label_methods = %i[caption]
    assert_equal "Caption", ResourceForm.lookup_label(record(caption: "Caption", name: "Name"))
  ensure
    ResourceForm.config.lookup_label_methods = original
  end
end
