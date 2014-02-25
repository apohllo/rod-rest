require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/api'
require 'json'

module Rod
  module Rest
    describe API do
      include Rack::Test::Methods

      def app
        Rod::Rest::API
      end

      # We need different resource name for each test due to Sinatra.
      let(:resource_name)       { "cars_" + rand.to_s }
      let(:serializer)          { stub!.serialize(nil) { nil_body }.subject }
      let(:nil_body)            { nil }
      let(:plural_associations) { [] }
      let(:resource)            { resource = stub!.name { resource_name }.subject
                                  stub(resource).plural_associations { plural_associations }
                                  resource
      }

      before do
        Rod::Rest::API.build_api_for(resource,serializer: serializer)
      end

      describe "GET /cars" do
        let(:count)         { 3 }
        let(:count_body)    { Object.new.to_s }

        before do
          stub(resource).count { count }
          stub(serializer).serialize({count: count}) { count_body }
        end

        it "returns count of cars" do
          get "/#{resource_name}"
          last_response.status.should == 200
          last_response.body.should == count_body
        end

        it "returns 404 for non-existing car" do
          get "/non_existing"
          last_response.status.should == 404
        end
      end

      describe "GET /cars?name=Mercedes" do
        let(:property_name)         { "name" }
        let(:invalid_property_name) { "surname" }
        let(:property_value)        { "Mercedes" }
        let(:empty_property_value)  { "Audi" }
        let(:mercedes_300)          { Object.new }
        let(:mercedes_180)          { Object.new }
        let(:cars_body)             { Object.new.to_s }
        let(:empty_collection_body) { Object.new.to_s }

        before do
          stub(resource).find_all_by_name(property_value) { [mercedes_300,mercedes_180] }
          stub(resource).find_all_by_name(empty_property_value) { [] }
          stub(serializer).serialize([mercedes_300,mercedes_180]) { cars_body }
          stub(serializer).serialize([]) { empty_collection_body }
        end

        it "returns serialized cars matching given indexed property" do
          get "/#{resource_name}?#{property_name}=#{property_value}"
          last_response.status.should == 200
          last_response.body.should == cars_body
        end

        it "returns an empty array if there are no matching objects" do
          get "/#{resource_name}?#{property_name}=#{empty_property_value}"
          last_response.status.should == 200
          last_response.body.should == empty_collection_body
        end

        it "returns 404 for non-indexed property" do
          get "/#{resource_name}?#{invalid_property_name}=#{property_value}"
          last_response.status.should == 404
        end
      end

      describe "GET /cars/1" do
        let(:mercedes_300_id)       { 1 }
        let(:audi_a4_id)            { 2 }
        let(:mercedes_300)          { Object.new }
        let(:mercedes_300_response) { Object.new.to_s }

        before do
          stub(resource).find_by_rod_id(mercedes_300_id) { mercedes_300 }
          stub(resource).find_by_rod_id(audi_a4_id)  { nil }
          stub(serializer).serialize(mercedes_300) { mercedes_300_response }
        end

        it "returns serialized car" do
          get "/#{resource_name}/#{mercedes_300_id}"
          last_response.status.should == 200
          last_response.body.should == mercedes_300_response
        end

        it "returns 404 for non-existing car" do
          get "/#{resource_name}/#{audi_a4_id}"
          last_response.status.should == 404
        end
      end

      describe "GET /cars/1/drivers" do
        let(:relation_name)   { "drivers" }
        let(:mercedes_300_id) { 1 }
        let(:mercedes_300)    { stub!.drivers_count { drivers_count }.subject }
        let(:audi_a4_id)      { 2 }
        let(:drivers_count)   { 4 }
        let(:drivers_response){ Object.new.to_s }
        let(:plural_associations) { [ property1 ] }
        let(:property1)       { stub!.name { relation_name }.subject }

        before do
          stub(resource).find_by_rod_id(mercedes_300_id) { mercedes_300 }
          stub(resource).find_by_rod_id(audi_a4_id) { nil }
          stub(serializer).serialize({count: drivers_count}) { drivers_response }
        end

        it "returns number of the drivers" do
          get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}"
          last_response.status.should == 200
          last_response.body.should == drivers_response
        end

        it "returns 404 for non-existing car" do
          get "/#{resource_name}/#{audi_a4_id}/#{relation_name}"
          last_response.status.should == 404
        end

        it "returns 404 for non-existing relation" do
          get "/#{resource_name}/#{mercedes_300_id}/non_existing"
          last_response.status.should == 404
        end
      end

      describe "GET /cars/1/drivers/0" do
        let(:relation_name)       { "drivers" }
        let(:plural_associations) { [ drivers_property ] }
        let(:drivers_property)    { stub!.name { relation_name }.subject }

        let(:mercedes_300_id)     { 1 }
        let(:audi_a4_id)          { 2 }
        let(:driver_index)        { 0 }
        let(:invalid_driver_index){ 10 }

        before do
          stub(resource).find_by_rod_id(mercedes_300_id) { mercedes_300 }
          stub(resource).find_by_rod_id(audi_a4_id)  { nil }
        end

        it "returns 404 for non-existing car" do
          get "/#{resource_name}/#{audi_a4_id}/#{relation_name}/#{driver_index}"
          last_response.status.should == 404
        end

        it "returns 404 for non-existing relation" do
          get "/#{resource_name}/#{mercedes_300_id}/non_existing/#{driver_index}"
          last_response.status.should == 404
        end

        describe "with one driver" do
          let(:mercedes_300)        { stub!.drivers { drivers }.subject }
          let(:drivers)             { [schumaher] }
          let(:schumaher)           { Object.new }
          let(:schumaher_response)  { Object.new.to_s }

          before do
            stub(serializer).serialize(schumaher) { schumaher_response }
          end

          it "returns the serialized driver" do
            get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}/#{driver_index}"
            last_response.status.should == 200
            last_response.body.should == schumaher_response
          end

          it "returns 404 for out-of-bounds driver" do
            get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}/#{invalid_driver_index}"
            last_response.status.should == 404
          end
        end
      end
    end
  end
end
