require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/api'

module Rod
  module Rest
    describe API do
      include Rack::Test::Methods

      def app
        Rod::Rest::API
      end

      context "resource API" do
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
          Rod::Rest::API.build_api_for(resource,serializer: serializer,resource_name: resource_name)
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

        describe "with three cars" do
          let(:mercedes_300_id)       { 1 }
          let(:mercedes_300)          { Object.new }
          let(:audi_a4_id)            { 2 }
          let(:audi_a4)               { Object.new }
          let(:fiat_panda_id)         { 3 }
          let(:fiat_panda)            { Object.new }
          let(:invalid_id)            { 4 }

          before do
            stub(resource).find_by_rod_id(mercedes_300_id) { mercedes_300 }
            stub(resource).find_by_rod_id(audi_a4_id)  { audi_a4 }
            stub(resource).find_by_rod_id(fiat_panda_id)  { fiat_panda }
            stub(resource).find_by_rod_id(invalid_id)  { nil }
          end

          describe "GET /cars/1" do
            let(:mercedes_300_response) { Object.new.to_s }

            before do
              stub(serializer).serialize(mercedes_300) { mercedes_300_response }
            end

            it "returns serialized car" do
              get "/#{resource_name}/#{mercedes_300_id}"
              last_response.status.should == 200
              last_response.body.should == mercedes_300_response
            end

            it "returns 404 for non-existing car" do
              get "/#{resource_name}/#{invalid_id}"
              last_response.status.should == 404
            end
          end

          describe "GET /cars/1..3" do
            let(:collection_response)   { Object.new.to_s }

            before do
              stub(serializer).serialize([mercedes_300,audi_a4,fiat_panda]) { collection_response }
            end

            it "returns collection of cars" do
              get "/#{resource_name}/#{mercedes_300_id}..#{fiat_panda_id}"
              last_response.status.should == 200
              last_response.body.should == collection_response
            end

            it "only returns non-nil elements" do
              get "/#{resource_name}/#{mercedes_300_id}..#{invalid_id}"
              last_response.status.should == 200
              last_response.body.should == collection_response
            end
          end

          describe "GET /cars/1,3" do
            let(:collection_response)   { Object.new.to_s }

            before do
              stub(serializer).serialize([mercedes_300,fiat_panda]) { collection_response }
            end

            it "returns collection of cars" do
              get "/#{resource_name}/#{mercedes_300_id},#{fiat_panda_id}"
              last_response.status.should == 200
              last_response.body.should == collection_response
            end

            it "only returns non-nil elements" do
              get "/#{resource_name}/#{mercedes_300_id},#{fiat_panda_id},#{invalid_id}"
              last_response.status.should == 200
              last_response.body.should == collection_response
            end
          end
        end


        describe "GET /cars/1/drivers" do
          let(:relation_name)   { "drivers" }
          let(:mercedes_300_id) { 1 }
          let(:mercedes_300)    { stub!.drivers_count { drivers_count }.subject }
          let(:invalid_id)      { 2 }
          let(:drivers_count)   { 4 }
          let(:drivers_response){ Object.new.to_s }
          let(:plural_associations) { [ property1 ] }
          let(:property1)       { stub!.name { relation_name }.subject }

          before do
            stub(resource).find_by_rod_id(mercedes_300_id) { mercedes_300 }
            stub(resource).find_by_rod_id(invalid_id) { nil }
            stub(serializer).serialize({count: drivers_count}) { drivers_response }
          end

          it "returns number of the drivers" do
            get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}"
            last_response.status.should == 200
            last_response.body.should == drivers_response
          end

          it "returns 404 for non-existing car" do
            get "/#{resource_name}/#{invalid_id}/#{relation_name}"
            last_response.status.should == 404
          end

          it "returns 404 for non-existing relation" do
            get "/#{resource_name}/#{mercedes_300_id}/non_existing"
            last_response.status.should == 404
          end
        end

        describe "with three drivers" do
          let(:relation_name)       { "drivers" }
          let(:plural_associations) { [ drivers_property ] }
          let(:drivers_property)    { stub!.name { relation_name }.subject }

          let(:mercedes_300_id)     { 1 }
          let(:invalid_id)          { 2 }
          let(:schumaher_index)     { 0 }
          let(:kubica_index)        { 1 }
          let(:alonzo_index)        { 2 }
          let(:invalid_driver_index){ 3 }
          let(:mercedes_300)        { stub!.drivers { drivers }.subject }
          let(:drivers)             { [schumaher,kubica,alonzo] }
          let(:schumaher)           { Object.new }
          let(:kubica)              { Object.new }
          let(:alonzo)              { Object.new }

          before do
            stub(resource).find_by_rod_id(mercedes_300_id) { mercedes_300 }
            stub(resource).find_by_rod_id(invalid_id)  { nil }
          end

          describe "GET /cars/1/drivers/0" do
            let(:schumaher_response)  { Object.new.to_s }

            before do
              stub(serializer).serialize(schumaher) { schumaher_response }
            end

            it "returns 404 for non-existing car" do
              get "/#{resource_name}/#{invalid_id}/#{relation_name}/#{schumaher_index}"
              last_response.status.should == 404
            end

            it "returns 404 for non-existing relation" do
              get "/#{resource_name}/#{mercedes_300_id}/non_existing/#{schumaher_index}"
              last_response.status.should == 404
            end

            it "returns the serialized driver" do
              get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}/#{schumaher_index}"
              last_response.status.should == 200
              last_response.body.should == schumaher_response
            end

            it "returns 404 for out-of-bounds driver" do
              get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}/#{invalid_driver_index}"
              last_response.status.should == 404
            end
          end

          describe "GET /cars/1/drivers/0..2" do
            let(:collection_response)  { Object.new.to_s }

            before do
              stub(serializer).serialize(drivers) { collection_response }
            end

            it "returns the serialized drivers" do
              get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}/#{schumaher_index}..#{alonzo_index}"
              last_response.status.should == 200
              last_response.body.should == collection_response
            end

            it "only returns non-nil elements" do
              get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}/#{schumaher_index}..#{invalid_driver_index}"
              last_response.status.should == 200
              last_response.body.should == collection_response
            end
          end

          describe "GET /cars/1/drivers/0,2" do
            let(:collection_response)  { Object.new.to_s }

            before do
              stub(serializer).serialize([schumaher,alonzo]) { collection_response }
            end

            it "returns the serialized drivers" do
              get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}/#{schumaher_index},#{alonzo_index}"
              last_response.status.should == 200
              last_response.body.should == collection_response
            end

            it "only returns non-nil elements" do
              get "/#{resource_name}/#{mercedes_300_id}/#{relation_name}/#{schumaher_index},#{alonzo_index},#{invalid_driver_index}"
              last_response.status.should == 200
              last_response.body.should == collection_response
            end
          end
        end
      end

      context "metadata API" do
        before do
          API.build_metadata_api(metadata,serializer: serializer)
        end

        let(:metadata)        { Object.new }
        let(:serializer)      { stub!.dump(metadata)  { dumped_metadata }.subject }
        let(:dumped_metadata) { "metadata" }

        describe "GET /metadata" do
          it "retunrs the metadata" do
            get "/metadata"
            last_response.status == 200
            last_response.body == dumped_metadata
          end
        end
      end
    end
  end
end
