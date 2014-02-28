module Rod
  module Rest
    class Metadata
      ROD_KEY = /\ARod\b/

      attr_reader :description

      # Initializes the metadata via the options:
      # * description - text representation of the metadata
      # * parser - parser used to parse the text representation of the metadata
      # * resource_metadata_factory - factory used to create metadata for the
      #   resources
      def initialize(options={})
        @description = options.fetch(:description)
        parser = options[:parser] || JSON
        @resource_metadata_factory = options[:resource_metadata_factory] || ResourceMetadata
        @resources = create_resource_descriptions(parser.parse(@description, symbolize_names: true))
      end

      # Return collection of resource metadata.
      def resources
        @resources
      end

      # Returns the description of the metadata and the class name.
      def inspect
        "#{self.class}<#{@description.inspect}>"
      end

      # Returns the description of the metadata.
      def to_s
        @description.to_s
      end

      private
      def create_resource_descriptions(hash_description)
        hash_description.map do |name,description|
          next if restricted_name?(name)
          @resource_metadata_factory.new(name,description)
        end.compact
      end

      def restricted_name?(name)
        name.to_s =~ ROD_KEY
      end
    end
  end
end
