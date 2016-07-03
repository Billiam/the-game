module ItemClasses
  BOOST = ['7777', 'Warthog', 'Miniature Giant Space Hamster', 'Treasure Chest', 'Moogle', 'Buffalo', 'Biggs', 'Pizza', 'UUDDLRLRBA', 'Pokeball', 'Chocobo', 'Da Da Da Da Daaa Da DAA da da', 'Wedge', 'Bo Jackson']
  PROTECT = ['Varia Suit', 'Star', 'Tanooki Suit', 'Carbuncle', 'Gold Ring']
  ATTACK = ['Red Shell', 'Crowbar', 'Banana Peel']
  ATTACK_PLAYER = ['Master Sword', 'Charizard', 'Hard Knuckle', "Pandora's Box", 'Space Invaders', 'Hadouken', 'Green Shell', 'Fire Flower', 'Holy Water', 'Golden Gun', 'Fus Ro Dah', 'Box of Bees']
  
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