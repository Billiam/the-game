require_relative "./api_actor"
require_relative "../item_classes"
require_relative "../events"
require_relative "../reporter"

class ItemUser < ApiActor
  include Celluloid::Notifications

  attr_reader :store, :effects, :available_target
  
  def initialize(api_key, inventory = {})
    super(api_key, 60.5)

    @store = inventory
    @effects = []
  end

  def listen
    subscribe Events::ADD_ITEM, :add_item
    subscribe Events::EFFECTS, :set_effects
    subscribe Events::SET_TARGET, :set_target
  end
  
  def set_target(topic, username)
    @available_target = username if username
  end

  def run
    listen

    super
  end

  def set_effects(topic, effects)
    @effects = effects
  end

  def add_item(topic, id, name, description=nil, rarity=nil)
    @store[name] ||= []
    @store[name] << id
  end

  def remove_item(id, name)
    @store[name] ||= []
    @store[name].reject! { |existing| existing == id }
  end

  def priorities
    [:protect, :boost, :attack_player, :attack]
  end

  def protected?
    has_effect?(ItemClasses.protect)
  end
  
  def has_effect?(type)
    (self.effects & Array(type)).any?
  end
  
  def use_item(id, name, attack=false)
    self.class.make_request do
      begin
        result = self.client.use_item(id, attack ? available_target : nil)
        
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
    match = /You found a bonus item! <(?<id>.*)> \| <(?<name>.*)>/.match(message)
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

  def find_by_type(type)
    item_name = ItemClasses.by_type(type).find do |name|
      @store.fetch(name, []).any?
    end
    
    return false unless item_name
    
    { id: @store[item_name].first, name: item_name }
  end
  
  def find_by_unbuffed(type)
    item_names = available_effects(type)
    return false unless item_names.any?
    
    item_name = item_names.first

    { id: @store[item_name].first, name: item_name }
  end

  def use_type(type)
    if [:protect, :buff].include?(type)
      item = find_by_unbuffed(type)
    else
      item = find_by_type(type)
    end
    
    return false unless item

    use_item(item[:id], item[:name], type == :attack_player)
  end

  
  def available_effects(type)
    ItemClasses.by_type(type).select do |name|
      @store.fetch(name, []).any? && ! has_effect?(type)
    end
  end
  
  def should_use?(type)
    return ! protected? if type == :protect
    return available_effects(type).any? if type == :boost
    return available_target if type == :attack_player
    true
  end
  
  def tick
    priorities.find { |type| 
      should_use?(type) && use_type(type)
    }
  end
end