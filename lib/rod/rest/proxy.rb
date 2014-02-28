require 'rod/rest/exception'

module Rod
  module Rest
    class Proxy
      # Initialize new Proxy factory based on the +metadata+ and associated with
      # the +client+, used to fetch the descriptions of the objects.
      # Options:
      # * collection_proxy_factory - factory used to create collection proxies
      #   for plural associations
      def initialize(metadata,client,options={})
        @metadata = metadata
        @client = client
        @type = @metadata.name
        @collection_proxy_factory = options[:collection_proxy_factory] || CollectionProxy
        @klass = build_class(@metadata)
      end

      # Return new instance of a proxy object based on the +hash+ data.
      def new(hash)
        check_id(hash)
        proxy = @klass.new(hash[:rod_id],@type,@client,@collection_proxy_factory)
        @metadata.fields.each do |field|
          check_field(hash,field)
          proxy.instance_variable_set("@#{field.symbolic_name}",hash[field.symbolic_name])
        end
        @metadata.singular_associations.each do |association|
          check_association(hash,association)
          proxy.instance_variable_set(association_variable_name(association),hash[association.symbolic_name])
        end
        @metadata.plural_associations.each do |association|
          check_association(hash,association)
          proxy.instance_variable_set(count_variable_name(association),hash[association.symbolic_name][:count])
        end
        proxy
      end

      private
      def build_class(metadata)
        Class.new do
          instance_variable_set("@metadata",metadata)

          attr_reader :type,:rod_id

          # Initialize the object with its +rod_it+, +type+ and the +client+
          # used to fetch the referenced objects. Use +collection_proxy_factory+
          # to create the referenced objects.
          def initialize(rod_id,type,client,collection_proxy_factory)
            @rod_id = rod_id
            @type = type
            @client = client
            @collection_proxy_factory = collection_proxy_factory
          end

          # Detailed description of the object, e.g.
          # Proxy[Car]<rod_id:1,brand:Mercedes><owner:Person:1><drivers[3]>
          def inspect
            result = "Proxy[#{@type}]"
            result << "<#{inspect_fields}>"
            result << "<#{inspect_singular_associations}>"
            result << "<#{inspect_plural_associations}>"
            result
          end

          # Only reports the type of the proxy and its rod_id, e.g.
          # Car[1]
          def to_s
            "#{@type}[#{@rod_id}]"
          end

          metadata.fields.each do |field|
            attr_reader field.symbolic_name
          end

          metadata.singular_associations.each do |association|
            class_eval <<-END
              def #{association.symbolic_name}
                if defined?(@#{association.name})
                  return @#{association.name}
                end
                @#{association.name} = @client.fetch_object(@_#{association.name}_description)
              end
            END
          end

          metadata.plural_associations.each do |association|
            class_eval <<-END
              def #{association.name}
                if defined?(@#{association.name})
                  return @#{association.name}
                end
                @#{association.name} = @collection_proxy_factory.new(self,"#{association.name}",@_#{association.name}_count,@client)
              end
            END
          end

          private
          def inspect_fields
            metadata.fields.map do |field|
              "#{field.name}:#{self.send(field.symbolic_name)}"
            end.join(",")
          end

          def inspect_singular_associations
            metadata.singular_associations.map do |association|
              description = instance_variable_get("@_#{association.name}_description")
              "#{association.name}:#{description[:type]}:#{description[:rod_id]}"
            end.join(",")
          end

          def inspect_plural_associations
            metadata.plural_associations.map do |association|
              count = instance_variable_get("@_#{association.name}_count")
              "#{association.name}[#{count}]"
            end.join(",")
          end

          def metadata
            self.class.metadata
          end

          def self.metadata
            @metadata
          end
        end
      end

      def check_id(hash)
        unless hash.has_key?(:rod_id)
          raise InvalidData.new(missing_rod_id_message(hash))
        end
      end

      def check_field(hash,field)
        unless hash.has_key?(field.symbolic_name)
          raise InvalidData.new(missing_field_error_message(field,hash))
        end
      end

      def check_association(hash,association)
        unless hash.has_key?(association.symbolic_name)
          raise InvalidData.new(missing_association_error_message(association,hash))
        end
        if !hash[association.symbolic_name].nil? &&  ! Hash === hash[association.symbolic_name]
          raise InvalidData.new(not_hash_error_message(association,hash[association.symbolic_name]))
        end
      end

      def missing_rod_id_message(hash)
        "The data doesn't have a rod_id #{hash}"
      end

      def missing_field_error_message(field,hash)
        "The field '#{field.symbolic_name}' is missing in the hash: #{hash}"
      end

      def missing_association_error_message(association,hash)
        "The association '#{association.symbolic_name}' is missing in the hash: #{hash}"
      end

      def not_hash_error_message(association,value)
        "The association '#{association.symbolic_name}' is not a hash: #{value}"
      end

      def association_variable_name(association)
        "@_#{association.symbolic_name}_description"
      end

      def count_variable_name(association)
        "@_#{association.symbolic_name}_count"
      end
    end
  end
end
