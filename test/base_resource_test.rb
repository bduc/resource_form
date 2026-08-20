require "test_helper"

class BaseResourceTest < ActiveSupport::TestCase
  test "auto-detects string columns as text fields" do
    resource = ResourceCore.resolve(Publisher)
    assert_equal :text, resource.fields[:name][:as]
  end

  test "auto-detects belongs_to as lookup_one" do
    resource = ResourceCore.resolve(Book)
    assert_equal :lookup_one, resource.fields[:author][:as]
    assert_equal "Author", resource.fields[:author][:class_name]
  end

  test "keeps FK column alongside belongs_to association" do
    resource = ResourceCore.resolve(Book)
    refute_nil resource.fields[:author_id]
  end

  test "auto-detects date columns as date fields" do
    resource = ResourceCore.resolve(Book)
    assert_equal :date, resource.fields[:published_on][:as]
  end

  test "auto-detects boolean columns as boolean fields" do
    resource = ResourceCore.resolve(Book)
    assert_equal :boolean, resource.fields[:out_of_print][:as]
  end

  test "resolve returns anonymous resource when no explicit class" do
    result = ResourceCore.resolve(Publisher)
    assert_equal "Publisher", result.model_class_name
  end

  test "field can override auto-detection" do
    klass = Class.new(ResourceCore::BaseResource) do
      self.model_class_name = "Book"
      field :published_on, as: :datetime
    end
    assert_equal :datetime, klass.fields[:published_on][:as]
  end
end
