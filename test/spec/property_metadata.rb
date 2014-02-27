require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/property_metadata'

module Rod
  module Rest
    describe PropertyMetadata do
      let(:property_metadata) { PropertyMetadata.new(name,options) }

      describe "constructor" do
        it "forbids to create property without name" do
          lambda { PropertyMetadata.new(nil,{}) }.should raise_error(ArgumentError)
        end
      end

      describe "#name" do
        let(:options)       { { type: :integer } }
        let(:name)          { :age }

        it "converts its name to string" do
          property_metadata.name.should be_a(String)
        end

        it "returns the name of the poperty" do
          property_metadata.name.should == name.to_s
        end
      end

      describe "#indexed?" do
        let(:options)       { { type: :string, index: index } }
        let(:name)          { :brand }

        describe "with index" do
          let(:index) { :hash }

          it "returns true" do
            property_metadata.should be_indexed
          end
        end

        describe "without index" do
          let(:index) { nil }
          it "returns false" do
            property_metadata.should_not be_indexed
          end
        end
      end
    end
  end
end
