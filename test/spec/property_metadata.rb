require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/property_metadata'

module Rod
  module Rest
    describe PropertyMetadata do
      let(:property_metadata) { PropertyMetadata.new(name,options) }
      let(:name)              { :age }
      let(:options)           { { type: :integer } }

      describe "constructor" do
        it "forbids to create property without name" do
          lambda { PropertyMetadata.new(nil,{}) }.should raise_error(ArgumentError)
        end
      end

      describe "#name" do
        it "converts its name to string" do
          property_metadata.name.should be_a(String)
        end

        it "returns the name of the poperty" do
          property_metadata.name.should == name.to_s
        end
      end

      describe "#symbolic_name" do
        it "converts its symbolic name to string" do
          property_metadata.symbolic_name.should be_a(Symbol)
        end

        it "returns the symbolic name of the poperty" do
          property_metadata.symbolic_name.should == name.to_sym
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

      describe "#inspect" do
        let(:options)       { { type: :string, index: index } }
        let(:index)         { nil }

        it "reports the name of the property" do
          property_metadata.inspect.should match(/#{name}/)
        end

        context "without index" do
          it "doesn't report that it is indexed" do
            property_metadata.inspect.should_not match(/indexed/)
          end
        end

        context "with index" do
          let(:index)     { :hash }

          it "reports that it is indexed" do
            property_metadata.inspect.should match(/indexed/)
          end
        end
      end

      describe "#to_s" do
        it "reports the name of the property" do
          property_metadata.to_s.should match(/#{name}/)
        end
      end
    end
  end
end
