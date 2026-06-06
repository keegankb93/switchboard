module Switchboard
  class Event
    include Hookable

    attr_reader :name, :transitions

    def initialize(name, guard: Guard.new)
      @name = name
      @transitions = []
      @guard = guard
    end

    #
    # Defines a transition from the given state(s) to the given state.
    # Stores the transition for later reference.
    #
    # @param from [Array, Symbol] The state(s) to transition from.
    # @param to [Symbol] The state to transition to.
    # @param kwargs [Hash] Additional options for the transition.
    # @option kwargs [Symbol, Proc] :if The condition to evaluate before transitioning.
    # @option kwargs [Symbol, Proc] :unless The condition to evaluate before transitioning.
    # @return [void]
    def transition(from:, to:, **kwargs)
      @transitions << Transition.new(
        from: Array(from),
        to: to,
        guard: Guard.new(if_cond: kwargs[:if], unless_cond: kwargs[:unless])
      )
    end

    #
    # Check if the guard passes and we can call this event
    def passes_guard?(subject)
      @guard.passes?(subject)
    end

    #
    # Returns the transition for the given state, if one exists.
    def transition_for(subject, state)
      @transitions.find { |t| t.eligible?(subject, state) }
    end

    # Available event hooks
    # I feel like there's a better way to define or reference these
    def before(m = nil, &block)
      on(:before, m, &block)
    end

    def after(m = nil, &block)
      on(:after, m, &block)
    end
  end
end
