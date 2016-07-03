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
  
  def set_target(topic, username, effects=[])
    @available_target = { name: username, effects: effects } if username
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

  def have_item?(name)
    @store.fetch(name, []).any?
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

  def available_items(type)
    ItemClasses.by_type(type).select do |name|
      have_item?(name)
    end
  end

  def available_effects(type)
    available_items(type).reject { |name| has_effect?(name) }
  end
  
  def find_attack
    item_names = available_attacks
    
    return false unless item_names.any?
    
    first_item_by_name(item_names.first)
  end
  
  def find_by_type(type)
    item_name = available_items(type)
    
    return false unless item_name
    
    first_item_by_name(item_name)
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
      when :protect, :boost
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
      when :protect
        ! protected?
      when :boost
        available_effects(type).any?
      when :attack_player
        available_attacks
      else
        true
    end
  end
  
  def tick
    priorities.find { |type| 
      should_use?(type) && use_type(type)
    }
  end
end