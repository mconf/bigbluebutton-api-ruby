require 'securerandom'

class Forgery::Basic < Forgery
  def self.random_name(base)
    base + "-" + SecureRandom.hex(4)
  end
end
