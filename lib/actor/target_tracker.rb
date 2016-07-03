require_relative "./api_actor"
require_relative "../item_classes"
require_relative "../events"

class TargetTracker < ApiActor
  include Celluloid::Notifications
  
  def initialize(api_key, username, inventory = {})
    super(api_key, 30)

    @username = username
    @target = nil
  end
  
  def tick
    self.class.make_request do
      leaderboard = self.client.leaderboard
      select_target(leaderboard)
    end
  end
  
  def select_target(leaderboard)
    return unless leaderboard
    
    users = leaderboard.select do |user| 
      return false if user["PlayerName"].strip.downcase == @username.strip.downcase
      (user["Effects"] & ItemClasses.protect).none?
    end
    
    user = users.first
    notify user if user
  end
  
  def notify(user)
    publish Events::SET_TARGET, user["PlayerName"], user["Effects"]
  end
end