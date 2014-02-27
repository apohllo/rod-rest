require 'json'

module Rod
  module Rest
    class JsonSerializer
      # Serialize given Rod +object+ to JSON.
      # The serialized object looks as follows:
      # {
      #   rod_id: 1,                            # required +rod_id+
      #   type: "Car",                          # required +type+
      #   name: "Mercedes 300",                 # field value
      #   owner: { rod_id: 1, type: "Person" }  # singular association value
      #   drivers: { count: 3 }                 # plural association value
      # }
      def serialize(object)
        if object.is_a?(Rod::Model)
          serialize_rod_object(object)
        elsif object.respond_to?(:each)
          serialize_collection(object)
        else
          serialize_basic_value(object)
        end
      end

      private
      def serialize_rod_object(object)
        build_object_hash(object).to_json
      end

      def serialize_collection(collection)
        collection.map{|o| build_object_hash(o) }.to_json
      end

      def serialize_basic_value(value)
        value.to_json
      end

      def build_object_hash(object)
        result = { rod_id: object.rod_id, type: object.class.to_s }
        resource = object.class
        resource.fields.each do |field|
          result[field.name] = object.send(field.name)
        end
        resource.singular_associations.each do |association|
          associated = object.send(association.name)
          if associated
            result[association.name] = { rod_id: associated.rod_id, type: associated.class.to_s }
          else
            result[association.name] = nil
          end
        end
        resource.plural_associations.each do |association|
          result[association.name] = { count: object.send(association.name).size }
        end
        result
      end
    end
  end
end
