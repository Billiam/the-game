require "celluloid/current"

require_relative "./api_actor"
require_relative "../events"
require_relative "../reporter"

class PointObtainer < ApiActor
  include Celluloid::Notifications

  def initialize(api_key)
    super(api_key, 1.01)
  end

  def before_run
    listen
  end
  
  def listen
    subscribe Events::POINTS, :set_points
  end
  
  def set_points(topic, points)
    @points = points
  end
  
  def gaining_points?
    @points > 0
  end
  
  def frequency
    gaining_points? ? @frequency : @frequency * 30
  end
  
  def tick
    self.class.make_request do
      result = self.client.points

      notify result
      report result
    end
    
    super
  end
    
  def report(result)
    status = filtered_status(result)
    
    Reporter.say status
  end

  def filtered_status(result)
    ["Badges"].reduce(result.dup) do |accumulator, key|
      accumulator.delete(key)
      
      accumulator
    end
  end
  
  def notify(result)
    notify_items result
    notify_status result
    notify_points result
  end

  def notify_status(result)
    effects = result["Effects"]
    publish Events::EFFECTS, effects
  end
  
  def notify_points(result)
    last_points = result["Messages"].map do |message|
      /gained (?<points>[-\d.]+) points!/.match(message)
    end.compact.first
    
    publish Events::POINTS, last_points[:points].to_f
  end
  
  def notify_items(result)
    items = result["Item"]
    return unless items

    items['Fields'].each do |item|
      publish Events::ADD_ITEM, item['Id'], item['Name'], item['Description'], item['Rarity']
    end
  end
end
