require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/collection_proxy'

module Rod
  module Rest
    describe CollectionProxy do
      let(:collection)        { CollectionProxy.new(mercedes_proxy,association_name,size,client) }
      let(:mercedes_proxy)    { Object.new }
      let(:association_name)  { "drivers" }
      let(:size)              { 0 }
      let(:client)            { Object.new }

      describe "#empty?" do
        describe "with 0 elements" do
          it "is empty" do
            collection.empty?.should == true
          end
        end

        describe "with 1 element" do
          let(:size)          { 1 }

          it "is not empty" do
            collection.empty?.should == false
          end
        end
      end

      describe "#size" do
        describe "with 5 elements" do
          let(:size)      { 5 }

          it "has size of 5" do
            collection.size.should == size
          end
        end
      end

      describe "with car proxy" do
        let(:car_type)          { "Car" }
        let(:mercedes_300_id)   { 1 }

        describe "with 3 drivers" do
          let(:size)        { 3 }
          let(:schumaher)   { Object.new }
          let(:kubica)      { Object.new }
          let(:alonzo)      { Object.new }

          describe "#[index]" do
            before do
              stub(client).fetch_related_object(mercedes_proxy,association_name,1) { kubica }
              stub(client).fetch_related_object(mercedes_proxy,association_name,5) { raise MissingResource.new("/cars/#{mercedes_300_id}/drivers/5") }
            end

            it "returns drivers by index" do
              collection[1].should == kubica
            end

            it "returns nil in case of out of bounds driver" do
              collection[5].should == nil
            end
          end

          describe "#[lower..upper]" do
            before do
              stub(client).fetch_related_objects(mercedes_proxy,association_name,0..2) { [schumaher,kubica,alonzo] }
            end

            it "returns drivers by index range" do
              collection[0..2].should == [schumaher,kubica,alonzo]
            end
          end

          describe "#first" do
            before do
              stub(client).fetch_related_object(mercedes_proxy,association_name,0) { schumaher }
            end

            it "returns the first driver" do
              collection.first.should == schumaher
            end
          end

          describe "#last" do
            before do
              stub(client).fetch_related_object(mercedes_proxy,association_name,2) { alonzo }
            end

            it "returns the last driver" do
              collection.last.should == alonzo
            end
          end

          describe "#each" do
            before do
              stub(client).fetch_related_objects(mercedes_proxy,association_name,0..2) { [schumaher,kubica,alonzo] }
            end

            it "iterates over the drivers" do
              drivers = [schumaher,kubica,alonzo]
              collection.each do |driver|
                driver.should == drivers.shift
              end
              drivers.size.should == 0
            end

            it "allows to chain the calls" do
              drivers = [schumaher,kubica,alonzo]
              collection.each.map{|e| e }.should == drivers
            end
          end
        end
      end
    end
  end
end
