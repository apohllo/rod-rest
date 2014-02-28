# rod-rest

REST API for [Ruby Object Database](https://github.com/apohllo/rod)


## Server

Starting the server is as simple as:

```ruby
SomeDatabase.instance.open_database("path/to/rod/database")
Rod::Rest::API.start_with_database(SomeDatabase.instance)
```

It starts Sinatra application listening by default on port 4567.

## Client

The client requires a `http_client` to be passed to the constructure. We
recommend Faraday, e.g.

```ruby
faraday = Faraday.new(url: "http://localhost:4567")
client = Rod::Rest::Client.new(http_client: faraday)
```

The client automatically fetches metadata, so there is no need to set it up.
Assuming you have the following Rod classes defined:

```ruby
class Person < Rod::Model
  field :name, :string, index: :hash
  field :surname, :string, index: :hash
end

class Car < Rod::Model
  field :brand, :string, index: :hash
  has_one :owner, class_name: "Person"
  has_many :drivers, class_name: "Person"
end
```


The client provides the following calls

```ruby
# find person by ROD id
client.find_person(1)

# find several people by their ROD ids
client.find_people(1,2,3)
# or
client.find_people(1..3)

# find person by name
client.find_person_by_name("Albert")

# find person by surname
client.find_person_by_surname

# find car by bran
car = client.find_car_by_brand("Mercedes")
car.owner                                   # returns proxy to singular association
car.drivers                                 # returns collection proxy
car.drivers.each do |driver|
  puts driver.name
end

car.drivers[1..2].each do |driver|          # negative indices are not yet supported
  puts driver.surname
end
```
  
There are also some more low API call supported, by usually when you get the
first object of some larger graph, there is no need to use them.


## License

(The MIT/X11 License)

Copyright (c) 2014 Aleksander Pohl

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Feedback

* mailto:apohllo@o2.pl
