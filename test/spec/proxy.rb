require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/proxy'

module Rod
  module Rest
    describe Proxy do
      let(:proxy)               { Proxy.new(metadata,client,collection_proxy_factory: collection_proxy_factory) }
      let(:metadata)            { metadata = stub!.fields { [id_field,name_field] }.subject
                                  stub(metadata).singular_associations { [owner_association] }
                                  stub(metadata).plural_associations { [drivers_association] }
                                  stub(metadata).name { car_type }
                                  metadata
      }
      let(:client)              { client = stub!.fetch_object(schumaher_hash) { schumaher_object }.subject }
      let(:collection_proxy_factory) { stub!.new(anything,drivers_association_name,drivers_count,client) { collection_proxy }.subject }
      let(:collection_proxy)    { Object.new }
      let(:id_field)            { property = stub!.symbolic_name { :rod_id }.subject
                                  stub(property).name { "rod_id" }
                                  property
      }
      let(:name_field)          { property = stub!.symbolic_name { :name }.subject
                                  stub(property).name { "name" }
                                  property
      }
      let(:owner_association)   { property = stub!.symbolic_name { :owner }.subject
                                  stub(property).name { "owner" }
                                  property
      }
      let(:drivers_association) { property = stub!.symbolic_name { drivers_association_name.to_sym }.subject
                                  stub(property).name { drivers_association_name }
                                  property
      }
      let(:drivers_association_name)  { "drivers"}

      let(:car_type)            { "Test::Car" }
      let(:mercedes_300_hash)   { { rod_id: mercedes_300_id, name: mercedes_300_name, type: car_type,
                                    owner: schumaher_hash, drivers: { count: drivers_count } } }
      let(:mercedes_300_id)     { 1 }
      let(:mercedes_300_name)   { "Mercedes 300" }

      let(:person_type)         { "Test::Person" }
      let(:drivers_count)       { 1 }
      let(:schumaher_hash)      { { rod_id: schumaher_id, type: person_type } }
      let(:schumaher_id)        { 2 }
      let(:schumaher_object)    { Object.new }
      let(:owner_object)        { schumaher_object }
      let(:first_driver_object) { schumaher_object }

      it "creates new instances" do
        proxy.new(mercedes_300_hash).should_not == nil
      end

      it "refuses to create instances with missing rod_id" do
        lambda { proxy.new({}) }.should raise_error(InvalidData)
      end

      it "refuses to create instances with missing type" do
        lambda { proxy.new({rod_id: mercedes_300_id}) }.should raise_error(InvalidData)
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

        it "has a valid 'owner' singular association" do
          mercedes_300.owner.should == owner_object
        end

        it "has a valid 'drivers' plural association" do
          mercedes_300.drivers.should == collection_proxy
        end

        context "caching singular associations" do
          let(:client)  {mock!.fetch_object(schumaher_hash) { schumaher_object }.once.subject }

          it "caches 'owner' singular association" do
            mercedes_300.owner
            mercedes_300.owner
          end
        end

        context "caching plural associations" do
          let(:collection_proxy_factory)  { mock!.new(anything,drivers_association_name,drivers_count,client) { collection_proxy }.once.subject }

          it "caches 'drivers' plural association" do
            mercedes_300.drivers
            mercedes_300.drivers
          end
        end
      end
    end
  end
end
