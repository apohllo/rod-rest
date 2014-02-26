require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/property_metadata'

module Rod
  module Rest
    describe PropertyMetadata do
      let(:property_metadata) { PropertyMetadata.new(description) }

      describe "constructor" do
        it "forbids to create property without name" do
          lambda { PropertyMetadata.new({}) }.should raise_error(KeyError)
        end
      end

      describe "#name" do
        let(:description)       { { name: name, type: :integer } }
        let(:name)              { "age" }

        it "returns the name of the poperty" do
          property_metadata.name == name
        end
      end

      describe "#indexed?" do
        let(:description)       { { name: "brand", type: :string, index: index } }

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
