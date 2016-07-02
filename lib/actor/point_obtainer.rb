require_relative "./api_actor"
require_relative "../events"
require_relative "../reporter"

class PointObtainer < ApiActor
  include Celluloid::Notifications

  def initialize(api_key)
    super(api_key, 1.01)
  end

  def tick
    self.class.make_request do
      result = self.client.points

      notify_items result
      notify_status result

      Reporter.say result
    end
  end

  def notify_status(result)
    effects = result["Effects"]
    publish Events::EFFECTS, effects
  end

  def notify_items(result)
    items = result["Item"]
    return unless items

    items['Fields'].each do |item|
      publish Events::ADD_ITEM, item['Id'], item['Name'], item['Description'], item['Rarity']
    end
  end
end
