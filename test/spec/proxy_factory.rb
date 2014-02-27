require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/proxy_factory'

module Rod
  module Rest
    describe ProxyFactory do
      let(:factory)           { ProxyFactory.new(metadata) }
      let(:metadata)          { stub!.subject }
      let(:car_type)          { "Car" }
      let(:mercedes_300_hash) { { rod_id: mercedes_300_id, type: car_type } }

      it "builds new proxy from hash" do
        object = factory.build(mercedes_300_hash)
        object.rod_id.should == mercedes_300_id
      end
    end
  end
end
