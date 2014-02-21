module Rod
  module Rest
    class InvalidData < RuntimeError; end

    class Proxy
      # Initialize new Proxy factory based on the +metadata+ and associated with
      # the +client+, used to fetch the descriptions of the objects.
      # Options:
      # * metadata - metadata describing the remote object
      # * client - client used to access other objects
      # * type - the type of the proxy object
      # * collection_proxy_factory - factory used to create collection proxies
      #   for plural associations
      def initialize(options={})
        @metadata = options.fetch(:metadata)
        @client = options.fetch(:client)
        @type = options.fetch(:type)
        @collection_proxy_factory = options.fetch(:collection_proxy_factory)
        @klass = build_class(@metadata)
      end

      # Return new instance of a proxy object based on the +hash+ data.
      def new(hash)
        proxy = @klass.new(@type,@client,@collection_proxy_factory)
        @metadata.fields.each do |field|
          unless hash.has_key?(field.name)
            raise InvalidData.new(missing_field_error_message(field,hash))
          end
          proxy.instance_variable_set("@#{field.name}",hash[field.name])
        end
        @metadata.singular_associations.each do |association|
          unless hash.has_key?(association.name)
            raise InvalidData.new(missing_association_error_message(association,hash))
          end
          if !hash[association.name].nil? &&  ! Hash === hash[association.name]
            raise InvalidData.new(not_hash_error_message(association,hash[association.name]))
          end
          proxy.instance_variable_set(association_variable_name(association),hash[association.name])
        end
        proxy
      end

      private
      def build_class(metadata)
        Class.new do
          attr_reader :type

          def initialize(type,client,collection_proxy_factory)
            @type = type
            @client = client
            @collection_proxy_factory = collection_proxy_factory
          end

          metadata.fields.each do |field|
            attr_reader field.name
          end

          metadata.singular_associations.each do |association|
            class_eval <<-END
              def #{association.name}
                if defined?(@#{association.name})
                  return @#{association.name}
                end
                @#{association.name} = @client.fetch_object(@_#{association.name}_description)
              end
            END
          end

          metadata.plural_associations.each do |association|
            define_method association.name do
              @collection_proxy_factory.new(self,association.name,@client)
            end
          end
        end
      end

      def missing_field_error_message(field,hash)
        "The field '#{field.name}' is missing in the hash: #{hash}"
      end

      def missing_association_error_message(association,hash)
        "The association '#{association.name}' is missing in the hash: #{hash}"
      end

      def not_hash_error_message(association,value)
        "The association '#{association.name}' is not a hash: #{value}"
      end

      def association_variable_name(association)
        "@_#{association.name}_description"
      end
    end
  end
end
