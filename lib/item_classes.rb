module ItemClasses
  PROTECT = ['Varia Suit', 'Star', 'Tanooki Suit', 'Carbuncle', 'Gold Ring']
  COMMON_BOOST = ['Mushroom']
  BOOST = ['7777', 'Warthog', 'Rush the Dog', 'Miniature Giant Space Hamster', 'Pony', 'Moogle']
  POINTS = ['Treasure Chest', 'Buffalo', 'Biggs', 'Pizza', 'UUDDLRLRBA', 'Pokeball', 'Chocobo', 'Da Da Da Da Daaa Da DAA da da', 'Wedge', 'Skinny Guys', 'Bo Jackson']
  ATTACK = ['Crowbar', 'Red Shell']
  ATTACK_PLAYER = ['Master Sword', 'Buster Sword', 'Charizard', 'Rail Gun', 'SPNKR', 'Hard Knuckle', 'Box of Bees', "Pandora's Box", 'Hadouken', 'Banana Peel', 'Green Shell', 'Fire Flower', 'Holy Water', 'Golden Gun', 'Fus Ro Dah', 'Box of Bees']
  
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