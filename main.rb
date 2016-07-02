$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + "/lib"

Bundler.require
Dotenv.load

require "logger"

require "game_api"
require "throttle"
require "item_classes"

require "actor/item_user"
require "actor/item_store"
require "actor/point_obtainer"
require "actor/target_tracker"

require "celluloid/current"

class Game
  attr_reader :client

  def initialize(api_key)
    @item_store = ItemStore.new
    inventory = @item_store.inventory
    
    @items = ItemUser.new(api_key, inventory)
    @points = PointObtainer.new(api_key)
    @targeter = TargetTracker.new(api_key, ENV.fetch("PLAYER_NAME"))
  end
  
  def run
    @targeter.async.run

    @item_store.async.run    
    @items.async.run
    @points.async.run
    
    sleep
  end
end

game = Game.new(ENV.fetch("API_KEY"))
game.run
