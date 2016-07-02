require "yaml/store"

require_relative "../events"

class ItemStore
  include Celluloid
  include Celluloid::Notifications

  attr_reader :store

  def initialize
    @store = YAML::Store.new "item_store.yml"
  end

  def add_item(topic, id, name, description=nil, rarity=nil)
    store.transaction do
      items = store.fetch(name, { ids: []})

      items[:description] ||= description
      items[:rarity] ||= rarity

      items[:ids] << id
      store[name] = items
    end
  end

  def remove_item(topic, id, name)
    store.transaction do
      items = store.fetch(name, {ids: []})
      items[:ids].reject! { |existing| existing == id }
      
      store[name] = items
    end
  end

  def inventory
    store.transaction(true) do
      store.roots.reduce({}) do |acc, root|
        acc[root] = store[root].fetch(:ids, [])
        
        acc
      end
    end
  end
  
  def run
    subscribe Events::ADD_ITEM, :add_item
    subscribe Events::USE_ITEM, :remove_item
    
    loop { sleep 5 }
  end
end
