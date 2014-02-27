require 'bundler/setup'
require 'rod'
require 'ruby-debug'
require 'rod/rest'
require 'rack'

class Database < Rod::Database
end

class Model < Rod::Model
  database_class Database
end

class Car < Model
  field :brand, :string, index: :hash
  has_one :owner, class_name: "Person"
  has_many :drivers, class_name: "Person"
end

class Person < Model
  field :name, :string, index: :hash
  field :surname, :string, index: :hash
end

module Rod
  module Rest
    describe "end-to-end tests" do
      PATH = "data/end_to_end"
      SCHUMAHER_NAME = "Michael"
      SCHUMAHER_SURNAME = "Schumaher"
      KUBICA_NAME = "Robert"
      KUBICA_SURNAME = "Kubica"
      MERCEDES_300_NAME = "Mercedes 300"

      before(:all) do
        ::Database.instance.create_database(PATH)
        schumaher = Person.new(name: SCHUMAHER_NAME, surname: SCHUMAHER_SURNAME)
        schumaher.store
        kubica = Person.new(name: KUBICA_NAME, surname: KUBICA_SURNAME)
        kubica.store
        mercedes_300 = Car.new(brand: MERCEDES_300_NAME, owner: schumaher, drivers: [schumaher,kubica])
        mercedes_300.store
        audi_a4 = Car.new(brand: "Audi A4", owner: nil)
        audi_a4.store
        ::Database.instance.close_database
      end

      after(:all) do
        require 'fileutils'
        FileUtils.rm_rf(PATH)
      end

      before do
        ::Database.instance.open_database(PATH)
      end

      after do
        ::Database.instance.close_database
      end

      example "Schumaher is in the DB" do
        schumaher = Person.find_by_surname(SCHUMAHER_SURNAME)
        schumaher.name.should == SCHUMAHER_NAME
      end

      example "Mercedes 300 is in the DB" do
        mercedes_300 = Car.find_by_brand(MERCEDES_300_NAME)
        mercedes_300.owner.should == Person.find_by_surname(SCHUMAHER_SURNAME)
        mercedes_300.drivers[1].should == Person.find_by_surname(KUBICA_SURNAME)
      end

      describe "with REST API and client" do
        let(:client)        { Client.new(http_client: http_client) }
        let(:http_client)   { Faraday.new(url: "http://localhost:4567") }

        before(:all) do
          Thread.new { API.start_with_database(::Database.instance,{},logging: nil) }
        end

        after(:all) do
          #Thread.join
        end

        example "API serves the metadata" do
          sleep 0.5
          client.metadata.resources.size.should == 3
          person = client.metadata.resources.find{|r| r.name == "Person" }
          person.fields.size == 2
          person.fields.zip(%w{name surname}).each do |field,field_name|
            field.name.should == field_name
          end
          car = client.metadata.resources.find{|r| r.name == "Car" }
          car.fields.zip(%w{brand}).each do |field,field_name|
            field.name.should == field_name
          end
        end

        example "Schumaher might be retrieved by id" do
          schumaher_in_rod = Person.find_by_name(SCHUMAHER_NAME)
          schumaher_via_api = client.find_person(schumaher_in_rod.rod_id)
          schumaher_via_api.name.should == schumaher_in_rod.name
          schumaher_via_api.surname.should == schumaher_in_rod.surname
        end
      end
    end
  end
end
