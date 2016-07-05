module ItemClasses
  PROTECT = ['Varia Suit', 'Star', 'Tanooki Suit', 'Gold Ring']
  COMMON_BOOST = ['Mushroom']
  BOOST = ['Moogle', 'Rush the Dog', '7777', 'Warthog', 'Miniature Giant Space Hamster', 'Pony']
  POINTS = ['Treasure Chest', 'Buffalo', 'Biggs', 'Pizza', 'UUDDLRLRBA', 'Pokeball', 'Chocobo', 'Da Da Da Da Daaa Da DAA da da', 'Wedge', 'Skinny Guys', 'Bo Jackson']
  ATTACK = ['Crowbar', 'Red Shell']
  ATTACK_PLAYER = ['Golden Gun', 'Fus Ro Dah', "Pandora's Box", 'Fire Flower','Box of Bees']
  ATTACK_FIRST = ['Blue Shell']
  ATTACK_SELF_HIGH = ['Master Sword']
  ATTACK_SELF = ['Master Sword', 'Buster Sword', 'Charizard', 'Rail Gun', 'SPNKR',  'Hadouken', 'Red Crystal', 'Hard Knuckle', 'Holy Water', 'Banana Peel', 'Green Shell']
  ITEM_WASTER = ['TKO', 'Fus Ro Dah']
  POINT_BOUNCER = ['Carbuncle']
  
  #Roger Wilco # - You used <Roger Wilco> on cfein; 0 points for cfein!
  
  constants.each do |c|
    define_singleton_method(c.downcase) do
      by_type(c)
    end
  end
  
  def self.by_type(type)
    const_get(type.upcase, false) || []
  end
end