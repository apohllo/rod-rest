require 'bundler/setup'
require_relative 'test_helper'
require 'rod/rest/metadata'

module Rod
  module Rest
    describe Metadata do
      let(:metadata)                  { Metadata.new(description: description, parser: parser, resource_metadata_factory: resource_metadata_factory) }
      let(:parser)                    { stub!.parse(description,is_a(Hash)) { hash_description }.subject }
      let(:description)               { Object.new }
      let(:hash_description)          { { resource_name => resource_description, "Rod" => rod_description } }
      let(:resource_description)      { Object.new }
      let(:rod_description)           { Object.new }
      let(:resource_metadata_factory) { stub!.new(name: resource_name,description: resource_description) { resource_metadata }.subject }
      let(:resource_metadata)         { Object.new }
      let(:resource_name)             { "Resource" }

      it "creates the metadata from the description" do
        metadata.resources
        expect(parser).to have_received.parse(description,is_a(Hash))
      end

      it "returns collection of resource descriptions" do
        metadata.resources.should respond_to(:each)
      end

      it "skips Rod pseudo-resource description" do
        metadata.resources.size.should == hash_description.size - 1
      end

      it "creates the metadata description using the metadata factory" do
        metadata.resources.first
        expect(resource_metadata_factory).to have_received.new(name: resource_name,description: resource_description)
      end
    end
  end
end
