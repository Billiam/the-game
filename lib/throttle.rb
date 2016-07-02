class Throttle
  def initialize(frequency)
    @frequency = frequency || 0
    @last_call = Time.new(0)
  end

  def next_call
    @last_call + @frequency
  end

  def wait
    difference = next_call - Time.now

    sleep difference if difference > 0
  end

  def after
    wait
    yield
    @last_call = Time.now
  end
end