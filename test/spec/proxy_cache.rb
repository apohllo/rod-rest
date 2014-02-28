require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/proxy_cache'

module Rod
  module Rest
    describe ProxyCache do
      let(:cache)     { ProxyCache.new }
      let(:object)    { object = stub!.rod_id { object_id }.subject
                        stub(object).type { object_type }
                        object
      }
      let(:object_id)     { 1 }
      let(:object_type)   { "Car" }
      let(:description)   { {rod_id: object_id, type: object_type} }

      describe "#store" do
        it "stores objects" do
          cache.store(object).should == object
        end

        it "raises InvalidData if the object cannot be stored" do
          lambda { cache.store(Object.new) }.should raise_error(InvalidData)
        end
      end

      describe "#has_key?" do
        context "without object in the cache" do
          it "returns false" do
            cache.has_key?(description).should == false
          end
        end

        context "with object in the cache" do
          before do
            cache.store(object)
          end

          it "returns true" do
            cache.has_key?(description).should == true
          end
        end

        context "with invalid description" do
          let(:description) { Object.new }

          it "raises InvalidData exception" do
            lambda { cache.has_key?(description) }.should raise_error(InvalidData)
          end
        end
      end

      describe "#[description]" do
        context "with object in the cache" do
          before do
            cache.store(object)
          end

          it "returns the object" do
            cache[description].should == object
          end
        end

        context "without object in the cache" do
          it "raises CacheMissed exception" do
            lambda { cache[description] }.should raise_error(CacheMissed)
          end
        end

        context "with invalid description" do
          let(:description) { Object.new }

          it "raises InvalidData exception" do
            lambda { cache[description] }.should raise_error(InvalidData)
          end
        end
      end
    end
  end
end
