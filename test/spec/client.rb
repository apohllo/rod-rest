require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/client'
require 'json'

stub_class 'Rod::Rest::ProxyFactory'

module Rod
  module Rest
    describe Client do
      let(:client)        { Client.new(http_client: web_client,metadata: metadata, factory: factory) }
      let(:resource_name) { "Car" }
      let(:car_type)      { resource_name }
      let(:metadata)      { stub!.resources { [resource1] }.subject }
      let(:resource1)     { resource = stub!.name { resource_name }.subject
                            stub(resource).indexed_properties { indexed_properties }
                            stub(resource).plural_associations { plural_associations }
                            resource
      }
      let(:indexed_properties)  { [] }
      let(:plural_associations) { [] }
      let(:factory)       { stub!.subject }
      let(:response)      { stub!.status{ 200 }.subject }
      let(:invalid_id)    { 1000 }
      let(:invalid_index) { 2000 }
      let(:invalid_response) { stub!.status{ 404 }.subject }

      describe "#cars_count" do
        let(:web_client)        { stub!.get("/cars") { response }.subject }
        let(:json_cars_count)   { { count: 3 }.to_json }

        before do
          stub(response).body { json_cars_count }
        end

        it "returns the number of cars" do
          client.cars_count.should == 3
        end
      end

      describe "with two cars defined" do
        let(:mercedes_300_id)   { 1 }
        let(:mercedes_300_hash) { {rod_id: mercedes_300_id, type: car_type } }
        let(:mercedes_180_hash) { {rod_id: 2, type: car_type } }
        let(:mercedes_300_proxy){ Object.new }
        let(:mercedes_180_proxy){ Object.new }
        let(:factory)           { factory = stub!.build(mercedes_300_hash) { mercedes_300_proxy }.subject
                                  stub(factory).build(mercedes_180_hash) { mercedes_180_proxy }
                                  factory
        }

        describe "#find_cars_by_name(name)" do
          let(:car_name)          { "Mercedes" }
          let(:property_name)     { "name" }
          let(:web_client)        { stub!.get("/cars?#{property_name}=#{car_name}") { response }.subject }
          let(:json_cars)         { [mercedes_300_hash,mercedes_180_hash].to_json }
          let(:indexed_properties){ [indexed_property] }
          let(:indexed_property)  { stub!.name { property_name }.subject }

          before do
            stub(response).body { json_cars }
          end

          it "finds the cars by their name" do
            cars = client.find_cars_by_name(car_name)
            expected_cars = [mercedes_300_proxy,mercedes_180_proxy]
            cars.size.should == expected_cars.size
            cars.zip(expected_cars).each do |result,expected|
              result.should == expected
            end
          end
        end

        describe "with car response defined" do
          let(:web_client)        { web_client = stub!.get("/cars/#{mercedes_300_id}") { response }.subject
                                    stub(web_client).get("/cars/#{invalid_id}") { invalid_response }
                                    web_client
          }
          let(:json_mercedes_300) { mercedes_300_hash.to_json }

          before do
            stub(response).body { json_mercedes_300 }
          end

          describe "#find_car(rod_id)" do
            it "finds the car by its rod_id" do
              client.find_car(mercedes_300_id).should == mercedes_300_proxy
            end

            it "raises MissingResource exception for invalid car rod_id" do
              lambda { client.find_car(invalid_id)}.should raise_exception(MissingResource)
            end
          end

          describe "#fetch_object(car_stub)" do
            let(:car_stub)        { { rod_id: mercedes_300_id, type: car_type } }
            let(:invalid_id_stub) { { rod_id: invalid_id, type: car_type } }
            let(:invalid_type_stub) { { rod_id: mercedes_300_id, type: invalid_type } }
            let(:invalid_type)    { "InvalidType" }

            it "finds the car by its stub" do
              client.fetch_object(car_stub).should == mercedes_300_proxy
            end

            it "raises MissingResource execption for invalid car rod_id" do
              lambda { client.fetch_object(invalid_id_stub)}.should raise_exception(MissingResource)
            end

            it "raises APIError execption for invalid type" do
              lambda { client.fetch_object(invalid_type_stub)}.should raise_exception(APIError)
            end
          end
        end


        describe "with associations" do
          let(:plural_associations) { [plural_association] }
          let(:plural_association)  { stub!.name { association_name}.subject }
          let(:association_name)    { "drivers" }

          describe "#car_drivers_count(rod_id)" do
            let(:web_client)        { web_client = stub!.get("/cars/#{mercedes_300_id}/#{association_name}") { response }.subject
                                      stub(web_client).get("/cars/#{invalid_id}/#{association_name}") { invalid_response }
                                      web_client
            }
            let(:drivers_count)     { 3 }
            let(:json_driver_count) { { count: drivers_count }.to_json }


            before do
              stub(response).body { json_driver_count }
            end

            it "returns the number of car drivers" do
              client.car_drivers_count(mercedes_300_id).should == drivers_count
            end

            it "raises MissingResource exception for invalid car rod_id" do
              lambda { client.car_drivers_count(invalid_id)}.should raise_exception(MissingResource)
            end
          end

          describe "#car_driver(rod_id,index)" do
            let(:web_client)        { web_client = stub!.get("/cars/#{mercedes_300_id}/#{association_name}/#{schumaher_index}") { response }.subject
                                      stub(web_client).get("/cars/#{invalid_id}/#{association_name}/#{schumaher_index}") { invalid_response }
                                      stub(web_client).get("/cars/#{mercedes_300_id}/#{association_name}/#{invalid_index}") { invalid_response }
                                      web_client
            }
            let(:schumaher_index)   { 0 }
            let(:schumaher_hash)    { { rod_id: schumaher_id, name: "Schumaher", type: "Driver" } }
            let(:schumaher_json)    { schumaher_hash.to_json }
            let(:schumaher_proxy)   { Object.new }
            let(:schumaher_id)      { 1 }

            before do
              stub(response).body { schumaher_json }
              stub(factory).build(schumaher_hash) { schumaher_proxy }
            end

            it "returns the driver" do
              client.car_driver(mercedes_300_id,schumaher_index).should == schumaher_proxy
            end

            it "raises MissingResource exception for invalid car rod_id" do
              lambda { client.car_driver(invalid_id,schumaher_index)}.should raise_exception(MissingResource)
            end

            it "raises MissingResource exception for invalid index" do
              lambda { client.car_driver(mercedes_300_id,invalid_index)}.should raise_exception(MissingResource)
            end
          end
        end
      end
    end
  end
end
