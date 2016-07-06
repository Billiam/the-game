require "celluloid/current"

require_relative "./api_actor"
require_relative "../item_classes"
require_relative "../events"
require_relative "../reporter"

class ItemUser < ApiActor
  include Celluloid::Notifications

  attr_reader :store, :effects, :available_target, :points
  
  def initialize(api_key, player_name, inventory = {})
    super(api_key, 61)

    # Cheap deep clone
    @store = Marshal.load(Marshal.dump(inventory))
    
    @player_name = player_name.downcase
    @current_position = Float::INFINITY
    
    @effects = []
    @points = nil
    @used_item = false
  end

  def listen
    subscribe Events::ADD_ITEM, :add_item
    subscribe Events::EFFECTS, :set_effects
    subscribe Events::SET_TARGET, :set_target
    subscribe Events::POINTS, :set_points
    subscribe Events::SET_LEADERBOARD, :set_leaderboard
  end


  def tick
    return super if abort?

    result = priorities.find do |type|
      should_use?(type) && use_type(type)
    end

    @used_item = result

    super
  end

  def set_leaderboard(topic, leaderboard)
    position = leaderboard.find_index do |player|
      player["PlayerName"].strip.downcase == @player_name
    end
    
    @current_position = position ? position + 1 :  Float::INFINITY
  end

  def set_points(topic, points)
    @points = points
  end
  
  def set_target(topic, username, effects=[])
    @available_target = { name: username, effects: effects } if username
  end
  
  def before_run
    listen
  end
  
  def set_effects(topic, effects)
    @effects = effects
  end

  # local item storage. Move to new instance?
  def add_item(topic, id, name, description=nil, rarity=nil)
    @store[name] ||= []
    @store[name] << id
  end

  def remove_item(id, name)
    @store[name] ||= []
    @store[name].reject! { |existing| existing == id }
  end

  def priorities
    [
      :protection_boost,
      :go_big,
      :self_attack,
      :protect,
      :common_boost,
      :boost,
      :points,
      :attack_player,
      :attack
    ]
  end
  
  def losing_points?
    points < 0
  end
  
  # Test current effect and point state
  def common_boosting?
    has_effect?(ItemClasses.common_boost) && points > 1
  end
  
  # Test current inventory state + effect state, point state
  def common_boost_ready?
    [
      available_items(:common_boost).any?,
      available_items(:boost).length > 1,
      ! has_effect?(ItemClasses.boost),
      points == 1
    ].all?
  end
  
  # current inventory + effect state
  def boost_ready?
    available_effects(:boost).any? && common_boosting?
  end
  
  def self_attack_ready?
    high_self_attacks.any? ||
      (self_attacks.length > 3 && available_item_total(:attack_self) > 10)
  end
  
  def well_prepared?
    has_effect? ItemClasses.point_bouncer
  end
  
  def unprotected?
    ! has_effect?(ItemClasses.protect)
  end
  
  def vulnerable?
    @current_position.between?(1, 3)
  end
  
  def in_first?
    @current_position == 1
  end
  
  def go_big_ready?
    in_first? && well_prepared?
  end
  
  def wasting_items?
    has_effect? ItemClasses.item_waster
  end
  
  def has_effect?(type)
    (self.effects & Array(type)).any?
  end
  
  def have_item?(name)
    @store.fetch(name, []).any?
  end
  
  def item_count(name)
    @store.fetch(name, []).length
  end

  def high_self_attacks
    available_items(:attack_self_high) - effects
  end
  
  def self_attacks
    available_items(:attack_self) - effects
  end
  
  def available_attacks
    return [] unless @available_target
    
    enemy_effects = @available_target[:effects]

    available_items(:attack_player) - enemy_effects
  end
  
  def attack_item
    names = available_attacks
    return unless names.any?
    item_name = names.first
    
    { id: @store[item_name].first, name: item_name }
  end
  
  def use_item(id, name, attack=false)
    self.class.make_request do
      begin
        result = self.client.use_item(id, attack ? available_target[:name] : nil)
        
        remove_item(id, name)
        publish Events::USE_ITEM, id, name
        handle_item_response(result)
        
        Reporter.say result
    
        true
      rescue JSON::ParserError => e
        puts "Could not parse result #{id} - #{name}, #{e}"
        
        false
      end
    end
  end
  
  # "You found a bonus item! <6b7de0b4-cd86-402e-9fd3-d3026cf8adf4> | <Mushroom>"
  def add_bonus_item(message)
    match = /(bonus item|hidden treasure)! <(?<id>.*)> \| <(?<name>.*)>/.match(message)
    return nil unless match
    
    add_item(nil, match[:id], match[:name])
    publish Events::ADD_ITEM, match[:id], match[:name]
  end
  
  def handle_item_response(result)
    return unless result["Messages"]
    
    result["Messages"].each do |message|
      add_bonus_item(message)
    end
  end

  def available_items(type)
    ItemClasses.by_type(type).select do |name|
      have_item?(name)
    end
  end
  
  def available_item_total(type)
    ItemClasses.by_type(type).sum do
      item_count(type)
    end
  end

  def available_effects(type)
    available_items(type).reject { |name| has_effect?(name) }
  end
  
  def find_self_attack
    item_names = self_attacks

    return false unless item_names.any?

    first_item_by_name(item_names.first)
  end
  
  def find_attack
    item_names = available_attacks
    
    return false unless item_names.any?
    
    first_item_by_name(item_names.first)
  end
  
  def find_by_type(type)
    item_name = available_items(type)
    
    return false unless item_name
    
    first_item_by_name(item_name.first)
  end
  
  def find_by_unbuffed(type)
    item_names = available_effects(type)
    return false unless item_names.any?
    
    first_item_by_name(item_names.first)
  end
  
  def first_item_by_name(item_name)
    return unless @store[item_name] && @store[item_name].any?
    
    { id: @store[item_name].first, name: item_name }
  end
  
  def use_type(type)
    item = case type
      when :go_big
        find_by_type(:attack_first)
      when :self_attack
        find_self_attack
      when :protection_boost
        find_by_unbuffed(:point_bouncer)
      when :protect, :common_boost, :boost
        find_by_unbuffed(type)
      when :attack_player
        find_attack
      else
        find_by_type(type)
    end

    return false unless item

    use_item(item[:id], item[:name], type == :attack_player)
  end
  
  def should_use?(type)
    case type
      when :go_big
        go_big_ready?
      when :protection_boost
        in_first? || self_attack_ready?
      when :self_attack
        well_prepared?
      when :protect
        unprotected? && vulnerable?
      when :common_boost
        common_boost_ready?
      when :boost
        boost_ready?
      when :attack_player
        available_attacks.any?
      else #:attack and :points have no preconditions
        true
    end
  end
  
  def frequency
    @used_item ? @frequency : 10
  end
  
  def abort?
    ! points || wasting_items?
  end
end