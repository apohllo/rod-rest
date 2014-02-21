require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/proxy'

module Rod
  module Rest
    describe Proxy do
      let(:proxy)               { Proxy.new(metadata: metadata,client: client,type: car_type, collection_proxy_factory: collection_proxy_factory) }
      let(:metadata)            { metadata = stub!.fields { [id_field,name_field] }.subject
                                  stub(metadata).singular_associations { [owner_association] }
                                  stub(metadata).plural_associations { [drivers_association] }
                                  metadata
      }
      let(:client)              { client = stub!.fetch_object(schumaher_hash) { schumaher_object }.subject }
      let(:collection_proxy_factory) { stub!.new(anything,drivers_association_name,client) { collection_proxy }.subject }
      let(:collection_proxy)    { Object.new }
      let(:id_field)            { stub!.name { :rod_id }.subject }
      let(:name_field)          { stub!.name { :name }.subject }
      let(:owner_association)   { stub!.name { :owner }.subject }
      let(:drivers_association) { stub!.name { drivers_association_name }.subject }
      let(:drivers_association_name)  { :drivers }

      let(:car_type)            { "Test::Car" }
      let(:mercedes_300_hash)   { { rod_id: mercedes_300_id, name: mercedes_300_name, type: car_type,
                                    owner: { rod_id: schumaher_id, type: person_type} } }
      let(:mercedes_300_id)     { 1 }
      let(:mercedes_300_name)   { "Mercedes 300" }

      let(:person_type)         { "Test::Person" }
      let(:schumaher_hash)      { { rod_id: schumaher_id, type: person_type } }
      let(:schumaher_id)        { 2 }
      let(:schumaher_object)    { Object.new }
      let(:owner_object)        { schumaher_object }
      let(:first_driver_object) { schumaher_object }

      it "creates new instances" do
        proxy.new(mercedes_300_hash).should_not == nil
      end

      it "refuses to create instances from invalid data" do
        lambda { proxy.new({}) }.should raise_error(InvalidData)
      end

      describe "created instance" do
        let(:mercedes_300)      { proxy.new(mercedes_300_hash) }

        it "has a type" do
          mercedes_300.type.should == car_type
        end

        it "has an id" do
          mercedes_300.rod_id.should == mercedes_300_id
        end

        it "has a valid 'name' field" do
          mercedes_300.name.should == mercedes_300_name
        end

        it "has an valid 'owner' singular association" do
          mercedes_300.owner.should == owner_object
        end

        it "has a valid 'drivers' plural association" do
          mercedes_300.drivers.should == collection_proxy
        end
      end
    end
  end
end
