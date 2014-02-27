module Rod
  module Rest
    class PropertyMetadata
      attr_reader :name

      # Creates new property metadata using the +name+ and +options+.
      def initialize(name, options)
        raise ArgumentError.new("nil name") if name.nil?
        @name = name.to_s
        @index = options[:index]
      end

      # Returns true if the property is indexed.
      def indexed?
        !! @index
      end
    end
  end
end
