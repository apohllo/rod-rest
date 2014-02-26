module Rod
  module Rest
    class Metadata
      ROD_KEY = "Rod"

      attr_reader :description

      # Initializes the metadata via the options:
      # * description - text representation of the metadata
      # * parser - parser used to parse the text representation of the metadata
      # * resource_metadata_factory - factory used to create metadata for the
      #   resources
      def initialize(options={})
        @description = options.fetch(:description)
        parser = options[:parser] || YAML
        @resource_metadata_factory = options[:resource_metadata_factory] || ResourceMetadata
        @resources = create_resource_descriptions(parser.parse(@description))
      end

      # Return collection of resource metadata.
      def resources
        @resources
      end

      private
      def create_resource_descriptions(hash_description)
        hash_description.map do |name,resource_description|
          next if name == ROD_KEY
          @resource_metadata_factory.new(resource_description)
        end.compact
      end
    end
  end
end
