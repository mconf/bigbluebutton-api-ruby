# Test object that stores information about an API request
class TestApiRequest
  attr_accessor :opts       # options hash
  attr_accessor :id         # meetind id
  attr_accessor :mod_pass   # moderator password
  attr_accessor :name       # meeting name
  attr_accessor :method     # last api method called
  attr_accessor :response   # last api response
  attr_accessor :exception  # last exception
end
