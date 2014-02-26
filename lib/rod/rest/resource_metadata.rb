module Rod
  module Rest
    class ResourceMetadata
      attr_reader :name, :fields, :singular_associations, :plural_associations, :properties, :indexed_properties

      # Create new resource metadata. Options:
      # * +name+ - the name of the resource
      # * +description+ - hash-like representation of the resource
      # * +property_factory+ - factory used to create descriptions of the
      #   properties
      def initialize(options={})
        @name = options.fetch(:name)
        @property_factory = options[:property_factory] || Property
        description = options.fetch(:description)
        @fields = create_properties(description[:fields])
        @singular_associations = create_properties(description[:singular_associations])
        @plural_associations = create_properties(description[:plural_associations])
        @properties = @fields + @singular_associations + @plural_associations
        @indexed_properties = @properties.select{|p| p.indexed? }
      end

      private
      def create_properties(description)
        description.map do |property_description|
          @property_factory.new(property_description)
        end
      end
    end
  end
end
