module ItemClasses
  BOOST = ['7777', 'Warthog', 'Treasure Chest', 'Moogle','Buffalo', 'Biggs', 'Pizza', 'UUDDLRLRBA', 'Pokeball', 'Chocobo', 'Bo Jackson', 'Da Da Da Da Daaa Da DAA da da', 'Wedge', 'Mushroom']
  PROTECT = ['Varia Suit', 'Star', 'Tanooki Suit', 'Carbuncle', 'Gold Ring']
  ATTACK = ['Banana Peel', 'Red Shell', 'Crowbar']
  ATTACK_PLAYER = ['Master Sword', 'Charizard', 'Hard Knuckle', 'Space Invaders', 'Hadouken', 'Holy Water', 'Fire Flower', 'Golden Gun', 'Fus Ro Dah', 'Green Shell']
  
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