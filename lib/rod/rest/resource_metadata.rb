module Rod
  module Rest
    class ResourceMetadata
      attr_reader :name, :fields, :singular_associations, :plural_associations, :properties, :indexed_properties

      # Create new resource metadata for a resource with +name+ and
      # +description+. Options:
      # * +property_factory+ - factory used to create descriptions of the
      #   properties
      def initialize(name,description,options={})
        @name = name.to_s
        @property_factory = options[:property_factory] || PropertyMetadata
        @fields = create_properties(description[:fields])
        @singular_associations = create_properties(description[:has_one])
        @plural_associations = create_properties(description[:has_many])
        @properties = @fields + @singular_associations + @plural_associations
        @indexed_properties = @properties.select{|p| p.indexed? }
      end

      private
      def create_properties(description)
        if  description
          description.map do |property_description|
            @property_factory.new(*property_description)
          end
        else
          []
        end
      end
    end
  end
end
