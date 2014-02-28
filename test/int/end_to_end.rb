require 'bundler/setup'
require 'rod'
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
      def verify_person_equality(person1,person2)
        person1.name.should == person2.name
        person1.surname.should == person2.surname
      end

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
          sleep 0.5
        end

        example "Client#inspect reports host and port" do
          client.inspect.should match(/4567/)
          client.inspect.should match(/localhost/)
        end

        example "API serves the metadata" do
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

        describe "with cars and drivers loaded from Rod" do
          let(:schumaher_in_rod)  { Person.find_by_name(SCHUMAHER_NAME) }
          let(:kubica_in_rod)     { Person.find_by_name(KUBICA_NAME) }
          let(:mercedes_in_rod)   { Car.find_by_brand(MERCEDES_300_NAME) }

          example "Schumaher might be retrieved by id" do
            schumaher_via_api = client.find_person(schumaher_in_rod.rod_id)
            verify_person_equality(schumaher_via_api,schumaher_in_rod)
          end

          example "Kubica might be retrieved by name" do
            kubica_via_api = client.find_people_by_name(KUBICA_NAME).first
            verify_person_equality(kubica_via_api,kubica_in_rod)
          end

          example "Mercedes might be retrieved by id" do
            mercedes_via_api = client.find_car(mercedes_in_rod.rod_id)
            mercedes_via_api.brand.should == mercedes_in_rod.brand
          end

          example "Mercedes owner is retrieved properly" do
            mercedes_via_api = client.find_car(mercedes_in_rod.rod_id)
            verify_person_equality(mercedes_via_api.owner,schumaher_in_rod)
          end

          example "Mercedes drivers are retrieved properly" do
            mercedes_via_api = client.find_car(mercedes_in_rod.rod_id)
            verify_person_equality(mercedes_via_api.drivers[0],schumaher_in_rod)
            verify_person_equality(mercedes_via_api.drivers[1],kubica_in_rod)
          end

          example "Mercedes drivers might be iterated over" do
            mercedes_via_api = client.find_car(mercedes_in_rod.rod_id)
            expected_drivers = [schumaher_in_rod,kubica_in_rod]
            mercedes_via_api.drivers.zip(expected_drivers).each do |driver,expected_driver|
              verify_person_equality(driver,expected_driver)
            end
          end
        end
      end
    end
  end
end
