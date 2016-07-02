require "ap"

module Reporter
  def self.say(*args)
    args = args.first if args.length == 1
    ap args, multiline: false
  end
end