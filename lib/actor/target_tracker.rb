require "celluloid/current"

require_relative "./api_actor"
require_relative "../item_classes"
require_relative "../events"

class TargetTracker < ApiActor
  include Celluloid::Notifications
  
  def initialize(api_key, ignore_users, inventory = {})
    super(api_key, 30)

    @ignore_users = Array(ignore_users).map { |name| name.strip.downcase }
    @target = nil
  end
  
  def tick
    self.class.make_request do
      leaderboard = self.client.leaderboard
      select_target(leaderboard)
    end
    
    super
  end
  
  def select_target(leaderboard)
    return unless leaderboard
    
    users = leaderboard.select do |user| 
      next false if @ignore_users.include?(user["PlayerName"].strip.downcase)
      (user["Effects"] & ItemClasses.protect).none?
    end
    
    user = users.first
    notify user if user
    
    notify_leaderboard users
  end
  
  def notify_leaderboard(leaderboard)
    publish Events::SET_LEADERBOARD, leaderboard
  end
  
  def notify(user)
    publish Events::SET_TARGET, user["PlayerName"], user["Effects"]
  end
end