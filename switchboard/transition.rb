module Switchboard
  #
  # Manages the transition information and whether or the transition itself can occur
  class Transition
    attr_reader :from, :to

    def initialize(from:, to:, guard: Guard.new)
      @from = Array(from)
      @to = to
      @guard = guard
    end

    #
    # @param state [Symbol] The state to check against the transition's from state.
    # @return [Boolean] Whether the state matches the transition's from state.
    def matches?(state)
      @from.include?(state)
    end

    #
    # @param subject [Object] The subject to evaluate the guard against.
    # @param state [Symbol] The state to check against the transition's from state.
    # @return [Boolean] Whether the transition is eligible to transition to the given state for the given subject.
    def eligible?(subject, state)
      matches?(state) && @guard.passes?(subject)
    end
  end
end
