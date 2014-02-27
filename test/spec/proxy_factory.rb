require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/proxy_factory'

module Rod
  module Rest
    describe ProxyFactory do
      let(:factory)           { ProxyFactory.new(metadata,client,proxy_class: proxy_class) }
      let(:metadata)          { [car_metadata,person_metadata] }
      let(:car_metadata)      { stub!.name { car_type }.subject }
      let(:person_metadata)   { stub!.name { person_type }.subject }
      let(:client)            { Object.new }
      let(:car_type)          { "Car" }
      let(:person_type)       { "Person" }
      let(:unknown_type)      { "Unknown" }
      let(:proxy_class)       { klass = stub!.new(car_metadata,client) { car_proxy_factory }.subject
                                stub(klass).new(person_metadata,client) { person_proxy_factory }
                                klass
      }
      let(:car_proxy_factory)     { stub!.new(mercedes_300_hash) { mercedes_300 }.subject }
      let(:person_proxy_factory)  { stub!.new(schumaher_hash) { schumaher }.subject }
      let(:mercedes_300_hash)     { { rod_id: mercedes_300_id, type: car_type } }
      let(:schumaher_hash)        { { rod_id: schumaher_id, type: person_type } }
      let(:unknown_hash)          { { rod_id: unknown_id, type: unknown_type } }
      let(:mercedes_300_id)       { 1 }
      let(:schumaher_id)          { 2 }
      let(:unknown_id)            { 3 }
      let(:mercedes_300)          { Object.new }
      let(:schumaher)             { Object.new }

      it "builds new car from hash" do
        factory.build(mercedes_300_hash).should == mercedes_300
      end

      it "builds new person proxy from hash" do
        factory.build(schumaher_hash).should == schumaher
      end

      it "raises UnknownResource for unknown resource type" do
        lambda { factory.build(unknown_hash) }.should raise_error(UnknownResource)
      end
    end
  end
end
