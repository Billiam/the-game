require "httparty"

class GameApi
  include HTTParty
  base_uri "thegame.nerderylabs.com"
  
  format :json
  

  def initialize(api_key)
    @key = api_key
  end
  
  def leaderboard
    self.class.get("/", default_options)
  end

  def points(options={})
    self.class.post("/points", default_options.merge(options))
  end

  def use_item(id, target = nil)
    query = {}
    query[:target] = target if target
    
    self.class.post("/items/use/#{id}", default_options.merge(query: query))
  end

  private
  def default_options
    {
      headers: {
        "apikey" => @key,
        "Accept" => "application/json"
      },
      timeout: 10
    }
  end
end