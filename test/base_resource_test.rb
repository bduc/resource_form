require "test_helper"

class BaseResourceTest < ActiveSupport::TestCase
  test "auto-detects string columns as text fields" do
    resource = ResourceForm::BaseResource.for(Province)
    assert_equal :text, resource.fields[:name][:as]
  end

  test "auto-detects belongs_to as lookup_one" do
    resource = ResourceForm::BaseResource.for(Federation)
    assert_equal :lookup_one, resource.fields[:province][:as]
    assert_equal "Province", resource.fields[:province][:class_name]
  end

  test "keeps FK column alongside belongs_to association" do
    resource = ResourceForm::BaseResource.for(Federation)
    refute_nil resource.fields[:province_id]
  end

  test "auto-detects date columns as date fields" do
    resource = ResourceForm::BaseResource.for(Member)
    assert_equal :date, resource.fields[:birth_date][:as]
  end

  test "auto-detects boolean columns as boolean fields" do
    resource = ResourceForm::BaseResource.for(Member)
    assert_equal :boolean, resource.fields[:label_magazine][:as]
  end

  test "for returns anonymous resource when no explicit class" do
    result = ResourceForm::BaseResource.for(Province)
    assert_equal "Province", result.model_class_name
  end

  test "field can override auto-detection" do
    klass = Class.new(ResourceForm::BaseResource) do
      self.model_class_name = "Member"
      field :birth_date, as: :datetime
    end
    assert_equal :datetime, klass.fields[:birth_date][:as]
  end
end
