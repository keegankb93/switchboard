module Switchboard
  module Errors
    class InitialStateExistsError < StandardError
      def initialize(initial_state)
        super("Initial state already exists. Current @initial_state: #{initial_state}")
      end
    end

    class EventFireError < StandardError
      def initialize(exception)
        super("Event fire error: #{exception}")
      end
    end
  end
end
