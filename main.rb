$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + "/lib"

require "rubygems"
require "bundler"
Bundler.setup(:default)

require "dotenv"
require "logger"
require "celluloid/current"

require "actor/item_user"
require "actor/item_store"
require "actor/point_obtainer"
require "actor/target_tracker"

Dotenv.load

class Game
  attr_reader :client

  def initialize(api_key)
    @item_store = ItemStore.new
    inventory = @item_store.inventory
    
    player_name = ENV.fetch("PLAYER_NAME")
    
    @items = ItemUser.new(api_key, player_name, inventory)
    @points = PointObtainer.new(api_key)
    @targeter = TargetTracker.new(api_key, [player_name])
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
