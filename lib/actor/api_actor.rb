require_relative "../throttle"

class ApiActor
  include Celluloid

  attr_reader :client

  def initialize(api_key, frequency = nil)
    @client = GameApi.new(api_key)
    @frequency = frequency
  end
  
  def frequency
    @frequency
  end
  
  def before_run
  end
  
  def run
    before_run
    tick
  end

  def self.make_request
    yield
  rescue Net::ReadTimeout, Net::OpenTimeout
    puts "timeout, waiting..."
    sleep 10
    retry
  rescue Errno::ECONNRESET
    sleep 30
    retry
  rescue JSON::ParserError
    sleep 5
  end

  def tick
    after(frequency, &method(:tick))
  end
end