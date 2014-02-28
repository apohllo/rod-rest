module Rod
  module Rest
    class PropertyMetadata
      attr_reader :name, :symbolic_name

      # Creates new property metadata using the +name+ and +options+.
      def initialize(name, options)
        raise ArgumentError.new("nil name") if name.nil?
        @name = name.to_s
        @symbolic_name = @name.to_sym
        @index = options[:index]
      end

      # Returns true if the property is indexed.
      def indexed?
        !! @index
      end

      # Detailed description of the porperty, i.e.
      # Rod::Rest::PropertyMetadata<name>
      def inspect
        indexed = indexed? ? ",indexed" : ""
        "Property<#{@name}#{indexed}>"
      end

      # Short description of the poperty.
      def to_s
        "'#{@name}' property"
      end
    end
  end
end
