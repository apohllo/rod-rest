require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/client'
require 'json'
require 'cgi'

stub_class 'Rod::Rest::ProxyFactory'

module Rod
  module Rest
    describe Client do
      let(:factory)       { stub!.subject }
      let(:metadata)      { stub!.resources { [resource1] }.subject }
      let(:resource1)     { resource = stub!.name { resource_name }.subject
                            stub(resource).indexed_properties { indexed_properties }
                            stub(resource).plural_associations { plural_associations }
                            resource
      }
      let(:resource_name) { "Car" }
      let(:indexed_properties)  { [] }
      let(:plural_associations) { [] }
      let(:car_type)      { resource_name }
      let(:response)      { stub!.status{ 200 }.subject }
      let(:web_client)    { Object.new }

      describe "without metadata provided to the client" do
        let(:client)                { Client.new(http_client: web_client,metadata_factory: metadata_factory, factory: factory) }
        let(:metadata_factory)      { stub!.new(description: metadata_description) { metadata }.subject }
        let(:metadata_description)  { "{}" }

        before do
          stub(web_client).get("/metadata")  { response }
          stub(response).body { metadata_description }
        end

        it "fetches the metadata via the API" do
          client.metadata.should == metadata
        end

        describe "when fetching the data via the API" do
          let(:json_cars_count)   { { count: 3 }.to_json }
          let(:cars_response)     { response = stub!.status { 200 }.subject
                                    stub(response).body { json_cars_count }
                                    response
          }

          before do
            stub(web_client).get("/cars") { cars_response }
          end

          it "fetches the metadata before the call" do
            client.cars_count.should == 3
          end
        end
      end

      describe "with metadata provided to the client" do
        let(:client)        { Client.new(http_client: web_client,metadata: metadata, factory: factory) }

        let(:invalid_id)    { 1000 }
        let(:invalid_index) { 2000 }
        let(:invalid_response) { stub!.status{ 404 }.subject }

        describe "#cars_count" do
          let(:json_cars_count)   { { count: 3 }.to_json }

          before do
            stub(web_client).get("/cars") { response }
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
            let(:json_cars)         { [mercedes_300_hash,mercedes_180_hash].to_json }
            let(:indexed_properties){ [indexed_property] }
            let(:indexed_property)  { stub!.name { property_name }.subject }

            before do
              stub(web_client).get("/cars?#{property_name}=#{car_name}") { response }
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
            let(:json_mercedes_300) { mercedes_300_hash.to_json }

            before do
              stub(web_client).get("/cars/#{mercedes_300_id}") { response }
              stub(web_client).get("/cars/#{invalid_id}") { invalid_response }
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
              let(:drivers_count)     { 3 }
              let(:json_driver_count) { { count: drivers_count }.to_json }


              before do
                stub(web_client).get("/cars/#{mercedes_300_id}/#{association_name}") { response }
                stub(web_client).get("/cars/#{invalid_id}/#{association_name}") { invalid_response }
                stub(response).body { json_driver_count }
              end

              it "returns the number of car drivers" do
                client.car_drivers_count(mercedes_300_id).should == drivers_count
              end

              it "raises MissingResource exception for invalid car rod_id" do
                lambda { client.car_drivers_count(invalid_id)}.should raise_exception(MissingResource)
              end
            end

            describe "with reponse defined" do
              let(:schumaher_index)   { 0 }
              let(:schumaher_hash)    { { rod_id: schumaher_id, name: "Schumaher", type: "Driver" } }
              let(:schumaher_json)    { schumaher_hash.to_json }
              let(:schumaher_proxy)   { Object.new }
              let(:schumaher_id)      { 1 }

              before do
                stub(web_client).get("/cars/#{mercedes_300_id}/#{association_name}/#{schumaher_index}") { response }
                stub(web_client).get("/cars/#{invalid_id}/#{association_name}/#{schumaher_index}") { invalid_response }
                stub(web_client).get("/cars/#{mercedes_300_id}/#{association_name}/#{invalid_index}") { invalid_response }
                stub(response).body { schumaher_json }
                stub(factory).build(schumaher_hash) { schumaher_proxy }
              end

              describe "#car_driver(rod_id,index)" do
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

              describe "#fetch_related_object(subject,relation,index)" do
                let(:association_name)        { "drivers" }
                let(:invalid_association_name){ "owners" }
                let(:invalid_type)            { "InvalidType" }
                let(:proxy_with_invalid_id)   { proxy = stub!.rod_id { invalid_id }.subject
                                                stub(proxy).type { car_type }
                                                proxy
                }
                let(:proxy_with_invalid_type) { proxy = stub!.rod_id { mercedes_300_id }.subject
                                                stub(proxy).type { invalid_type }
                                                proxy
                }

                before do
                  stub(mercedes_300_proxy).rod_id { mercedes_300_id }
                  stub(mercedes_300_proxy).type { car_type }
                end

                it "returns the driver" do
                  client.fetch_related_object(mercedes_300_proxy,association_name,schumaher_index).should == schumaher_proxy
                end

                it "raises MissingResource exception for invalid car proxy id" do
                  lambda { client.fetch_related_object(proxy_with_invalid_id,association_name,schumaher_index)}.should raise_exception(MissingResource)
                end

                it "raises MissingResource exception for invalid index" do
                  lambda { client.fetch_related_object(mercedes_300_proxy,association_name,invalid_index)}.should raise_exception(MissingResource)
                end

                it "raises APIError exception for invalid resource type" do
                  lambda { client.fetch_related_object(proxy_with_invalid_type,association_name,schumaher_index)}.should raise_exception(APIError)
                end

                it "raises APIError exception for invalid association name" do
                  lambda { client.fetch_related_object(mercedes_300_proxy,invalid_association_name,schumaher_index)}.should raise_exception(APIError)
                end
              end
            end
          end
        end
      end
    end
  end
end
