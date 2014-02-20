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

      def json_body
        JSON.parse(last_response.body)
      end

      # We need different resource name for each test due to Sinatra.
      let(:resource_name) { "cars_" + rand.to_s }
      let(:resource)      { stub!.subject }

      before do
        Rod::Rest::API.build_api_for(resource,resource_name)
      end

      describe "GET /cars" do
        let(:resource)      { resource = stub!.count { count }.subject
                              stub(resource).plural_associations { [] }
                              resource
                            }
        let(:count)         { 3 }


        it "returns count of cars" do
          get "/#{resource_name}"
          last_response.status.should == 200
          json_body.should == {"count" => count}
        end

        it "returns 404 for non-existing car" do
          get "/non_existing"
          last_response.status.should == 404
        end
      end

      describe "GET /cars?name=Mercedes" do
        let(:resource)        { resource = stub!.find_all_by_name(property_value) { [car1,car2] }.subject
                                stub(resource).find_all_by_name(empty_property_value) { [] }.subject
                                stub(resource).plural_associations { [] }
                                resource
                              }
        let(:property_name)         { "name" }
        let(:invalid_property_name) { "surname" }
        let(:property_value)        { "Mercedes" }
        let(:empty_property_value)  { "Audi" }
        let(:car_id1)               { 1 }
        let(:car_id2)               { 2 }
        let(:car1)                  { stub!.to_json { json_car1 }.subject }
        let(:car2)                  { stub!.to_json { json_car2 }.subject }
        let(:json_car1)             { {rod_id: car_id1, type: "Car"}.to_json }
        let(:json_car2)             { {rod_id: car_id2, type: "Car"}.to_json }

        it "returns cars matching given indexed property" do
          get "/#{resource_name}?#{property_name}=#{property_value}"
          last_response.status.should == 200
          json_body.should == [{"rod_id" => car_id1, "type" => "Car"}, {"rod_id" => car_id2, "type" => "Car"} ]
        end

        it "returns an empty array if there are no matching objects" do
          get "/#{resource_name}?#{property_name}=#{empty_property_value}"
          last_response.status.should == 200
          json_body.should == []
        end

        it "returns 404 for non-indexed property" do
          get "/#{resource_name}?#{invalid_property_name}=#{property_value}"
          last_response.status.should == 404
        end
      end

      describe "GET /cars/1" do
        let(:car_id1)       { 1 }
        let(:car_id2)       { 2 }
        let(:resource)      { stub(resource=Object.new).find_by_rod_id(car_id1) { object_1 }
                              stub(resource).find_by_rod_id(car_id2)  { nil }
                              stub(resource).plural_associations { [] }
                              resource
        }
        let(:object_1)      { stub!.to_json { json_object_1 }.subject }
        let(:json_object_1) { { rod_id: car_id1, type: "Car" }.to_json }

        it "returns JSON description of the car" do
          get "/#{resource_name}/#{car_id1}"
          last_response.status.should == 200
          json_body.should == { "rod_id" => car_id1, "type" => "Car" }
        end

        it "returns 404 for non-existing car" do
          get "/#{resource_name}/#{car_id2}"
          last_response.status.should == 404
        end
      end

      describe "GET /cars/1/drivers" do
        let(:relation_name) { "drivers" }
        let(:car_id1)       { 1 }
        let(:car_id2)       { 2 }
        let(:drivers_count) { 4 }
        let(:resource)      { stub(resource=Object.new).find_by_rod_id(car_id1) { object_1 }
                              stub(resource).find_by_rod_id(car_id2)  { nil }
                              stub(resource).plural_associations { plural_associations }
                              resource
        }
        let(:object_1)      { stub!.drivers_count { drivers_count }.subject }
        let(:plural_associations) { [ property1 ] }
        let(:property1)     { stub!.name { relation_name }.subject }

        it "returns number of the drivers" do
          get "/#{resource_name}/#{car_id1}/#{relation_name}"
          last_response.status.should == 200
          json_body.should == { "count" => drivers_count }
        end

        it "returns 404 for non-existing car" do
          get "/#{resource_name}/#{car_id2}/#{relation_name}"
          last_response.status.should == 404
        end

        it "returns 404 for non-existing relation" do
          get "/#{resource_name}/#{car_id1}/non_existing"
          last_response.status.should == 404
        end
      end

      describe "GET /cars/1/drivers/0" do
        let(:relation_name) { "drivers" }
        let(:car_id1)       { 1 }
        let(:car_id2)       { 2 }
        let(:drivers_count) { 5 }
        let(:driver_index)  { 0 }
        let(:invalid_driver_index)  { 10 }
        let(:driver_id)     { 5 }
        let(:resource)      { stub(resource=Object.new).find_by_rod_id(car_id1) { car_1 }
                              stub(resource).find_by_rod_id(car_id2)  { nil }
                              stub(resource).plural_associations { plural_associations }
                              resource
        }
        let(:plural_associations) { [ property1 ] }
        let(:property1)     { stub!.name { relation_name }.subject }
        let(:car_1)         { stub!.drivers { drivers }.subject }
        let(:drivers)       { [driver_1] }
        let(:driver_1)      { stub!.to_json { json_driver_1 }.subject }
        let(:json_driver_1) { { rod_id: driver_id, type: "Driver" }.to_json }



        it "returns JSON representation of the driver" do
          get "/#{resource_name}/#{car_id1}/#{relation_name}/#{driver_index}"
          last_response.status.should == 200
          json_body.should == { "rod_id" => driver_id, "type" => "Driver" }
        end

        it "returns 404 for non-existing car" do
          get "/#{resource_name}/#{car_id2}/#{relation_name}/#{driver_index}"
          last_response.status.should == 404
        end

        it "returns 404 for non-existing relation" do
          get "/#{resource_name}/#{car_id1}/non_existing/#{driver_index}"
          last_response.status.should == 404
        end

        it "returns 404 for out-of-bounds driver" do
          get "/#{resource_name}/#{car_id2}/#{relation_name}/#{invalid_driver_index}"
          last_response.status.should == 404
        end
      end

    end
  end
end
