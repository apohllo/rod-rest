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

      describe "#inspect" do
        let(:car_type)        { "Car" }
        before do
          stub(mercedes_proxy).type { car_type }
        end

        it "reports the type of the proxy object" do
          collection.inspect.should match(/#{car_type}/)
        end

        it "reports the name of the association" do
          collection.inspect.should match(/#{association_name}/)
        end

        it "reports size of the collection" do
          collection.inspect.should match(/#{size}/)
        end
      end

      describe "#to_s" do
        it "reports the size of the collection" do
          collection.to_s.should match(/#{size}/)
        end
      end

      describe "#to_s" do
      end

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

            it "caches retrieved objects" do
              collection[1]
              collection[1]
              expect(client).to have_received.fetch_related_object(mercedes_proxy,association_name,1) { kubica }.once
            end
          end

          describe "#[lower..upper]" do
            before do
              stub(client).fetch_related_objects(mercedes_proxy,association_name,0..2) { [schumaher,kubica,alonzo] }
            end

            it "returns drivers by index range" do
              collection[0..2].should == [schumaher,kubica,alonzo]
            end

            it "caches retrieved objects" do
              collection[0..2]
              collection[1]
              collection[1]
              expect(client).to have_received.fetch_related_objects(mercedes_proxy,association_name,0..2).once
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

        context "with 0 drivers" do
          let(:size)  { 0 }

          describe "#each" do
            it "doesn't call the block" do
              lambda { collection.each{|e| raise "Should not be executed" } }.should_not raise_error(Exception)
            end
          end
        end
      end
    end
  end
end
