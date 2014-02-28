require 'rod/rest/exception'

module Rod
  module Rest
    class CollectionProxy
      include Enumerable
      attr_reader :size

      # Initializes a CollectionPorxy.
      # * +:proxy+ - the object this collection belongs to
      # * +:association_name+ - the name of proxie's plural association this collection is returned for
      # * +:size+ - the size of the collection
      # * +:client+ - the REST API client
      def initialize(proxy,association_name,size,client)
        @proxy = proxy
        @association_name = association_name
        @size = size
        @client = client
        @cache = []
      end

      # Returns true if the collection is empty (i.e. its size == 0).
      def empty?
        self.size == 0
      end

      # Returns the index-th element of the collection.
      def [](index)
        begin
          if Range === index
            @cache[index] = @client.fetch_related_objects(@proxy,@association_name,index)
          else
            return @cache[index] unless @cache[index].nil?
            @cache[index] = @client.fetch_related_object(@proxy,@association_name,index)
          end
        rescue MissingResource
          nil
        end
      end

      # Returns the first element of the collection.
      def first
        self.size > 0 ? self[0] : nil
      end

      # Returns the last element of the collection.
      def last
        self.size > 0 ? self[size - 1] : nil
      end

      # Iterates over the elements of the collection.
      def each
        if block_given?
          self[0..@size-1].each do |object|
            yield object
          end
        else
          enum_for(:each)
        end
      end
    end
  end
end
