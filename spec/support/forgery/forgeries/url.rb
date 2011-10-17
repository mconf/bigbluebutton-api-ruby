class Forgery::Internet < Forgery
  def self.url
    "http://" + domain_name + top_level_domain + cctld + "/"
  end
end
