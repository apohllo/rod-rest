require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/resource_metadata'

module Rod
  module Rest
    describe ResourceMetadata do
      describe "with description of 2 fields, 1 singular association and 1 plural association" do
        let(:resource_metadata)       { ResourceMetadata.new(name,description, property_factory: property_factory) }
        let(:name)                    { :Car }
        let(:description)             { { fields: fields, has_one: singular_associations, has_many: plural_associations } }
        let(:fields)                  { [brand_field,age_field] }
        let(:singular_associations)   { [owner_association] }
        let(:plural_associations)     { [drivers_association] }
        let(:brand_field)             { Object.new }
        let(:brand_property)          { property = stub!.indexed? { true }.subject }
        let(:age_field)               { Object.new }
        let(:age_property)            { property = stub!.indexed? { false }.subject }
        let(:owner_association)       { Object.new }
        let(:owner_property)          { property = stub!.indexed? { false }.subject }
        let(:drivers_association)     { Object.new }
        let(:drivers_property)        { property = stub!.indexed? { false }.subject }
        let(:property_factory)        { factory = stub!.new(brand_field) { brand_property} .subject
                                        stub(factory).new(age_field) { age_property }
                                        stub(factory).new(owner_association) { owner_property }
                                        stub(factory).new(drivers_association) { drivers_property }
                                        factory
        }

        it "has a String name" do
          resource_metadata.name.should be_a(String)
        end

        it "returns its name" do
          resource_metadata.name.should == name.to_s
        end

        it "has 2 fields" do
          resource_metadata.fields.size.should == 2
        end

        it "allows to iterate over the fields" do
          resource_metadata.fields.should respond_to(:each)
        end

        it "uses the factory to create the fields" do
          resource_metadata.fields
          expect(property_factory).to have_received.new(brand_field)
          expect(property_factory).to have_received.new(age_field)
        end

        it "has 1 singular association" do
          resource_metadata.singular_associations.size.should == 1
        end

        it "allows to iterate over the singular associations" do
          resource_metadata.singular_associations.should respond_to(:each)
        end

        it "uses the factory to create the singular associations" do
          resource_metadata.singular_associations
          expect(property_factory).to have_received.new(owner_association)
        end

        it "has 1 plural association" do
          resource_metadata.plural_associations.size.should == 1
        end

        it "allows to iterate over the plural associations" do
          resource_metadata.plural_associations.should respond_to(:each)
        end

        it "uses the factory to create the plural associations" do
          resource_metadata.plural_associations
          expect(property_factory).to have_received.new(drivers_association)
        end

        it "has 4 properties" do
          resource_metadata.properties.size.should == 4
        end

        it "allows to iterate over the properties" do
          resource_metadata.properties.should respond_to(:each)
        end

        it "has 1 indexed property" do
          resource_metadata.indexed_properties.size.should == 1
        end

        it "allows to iterate over the indexed properties" do
          resource_metadata.indexed_properties.should respond_to(:each)
        end

        describe "#inspect" do
          it "reports the description of the metadata" do
            resource_metadata.inspect.should == description.inspect
          end
        end

        describe "#to_s" do
          it "reports the description of the metadata" do
            resource_metadata.to_s.should == description.to_s
          end
        end
      end
    end
  end
end
