module Rod
  module Rest
    class PropertyMetadata
      attr_reader :name

      # Creates new property metadata using the hash-like description.
      def initialize(description)
        @name = description.fetch(:name)
        @index = description[:index]
      end

      # Returns true if the property is indexed.
      def indexed?
        !! @index
      end
    end
  end
end
