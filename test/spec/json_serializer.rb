require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/json_serializer'

module Rod
  module Rest
    describe JsonSerializer do
      let(:serializer)            { JsonSerializer.new }
      let(:object)                { object = stub!.class { resource }.subject
                                    stub(object).rod_id { rod_id }
                                    stub(object).type { type }
                                    object
      }
      let(:rod_id)                { 1 }
      let(:type)                  { "Car" }
      let(:resource)              { resource = stub!.fields { fields }.subject
                                    stub(resource).singular_associations { singular_associations }
                                    stub(resource).plural_associations { plural_associations }
                                    resource
      }
      let(:fields)                { [] }
      let(:singular_associations) { [] }
      let(:plural_associations)   { [] }
      let(:result)                { JSON.parse(serializer.serialize(object),symbolize_names: true) }


      describe "resource without properties" do
        it "serializes its rod_id" do
          result[:rod_id].should == rod_id
        end

        it "serializes its type" do
          result[:type].should == type
        end
      end

      describe "resource with name field" do
        let(:fields)        { [name_field] }
        let(:name_field)    { stub!.name { field_name }.subject }
        let(:field_name)    { "brand" }
        let(:brand)         { "Mercedes" }

        before do
          stub(object).brand { brand }
        end

        it "serializes its name field" do
          result[:brand].should == brand
        end
      end

      describe "resource with 'owner' singular association" do
        let(:singular_associations) { [owner_association] }
        let(:owner_association)     { stub!.name { owner_association_name }.subject }
        let(:owner_association_name){ "owner" }
        let(:owner)                 { owner = stub!.rod_id { owner_rod_id }.subject
                                      stub(owner).type { owner_type }.subject
                                      owner
        }
        let(:owner_rod_id)          { 10 }
        let(:owner_type)            { "Person" }

        describe "with existing owner" do
          before do
            stub(object).owner { owner }
          end

          it "serializes rod_id of the owner" do
            result[:owner][:rod_id] == owner_rod_id
          end

          it "serializes type of the owner" do
            result[:owner][:type] == owner_type
          end
        end

        describe "without owner" do
          before do
            stub(object).owner { nil }
          end

          it "serializes the owner as nil" do
            result[:owner].should == nil
          end
        end
      end

      describe "resource with 'drivers' plural association" do
        let(:plural_associations)       { [drivers_association] }
        let(:drivers_association)       { stub!.name { driver_association_name }.subject }
        let(:driver_association_name)   { "drivers" }
        let(:drivers)                   { stub!.size { drivers_count }.subject }
        let(:drivers_count)             { 1 }

        before do
          stub(object).drivers { drivers }
        end

        it "serializes the number of associated objects" do
          result[:drivers][:count].should == drivers_count
        end
      end
    end
  end
end
