module Switchboard
  #
  # Represents an event which holds references to the transitions that the event performs
  class Event
    include Hookable

    attr_reader :name, :transitions

    def initialize(name, guard: Guard.new)
      @name = name
      @transitions = []
      @transitions_by_from = {}
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
      normalized_from = Array(from)

      transition = Transition.new(
        from: normalized_from,
        to: to,
        guard: Guard.new(if_cond: kwargs[:if], unless_cond: kwargs[:unless])
      )

      @transitions << transition

      normalized_from.each do |state|
        (@transitions_by_from[state] ||= []) << transition
      end
    end

    #
    # Check if the guard passes and we can call this event
    def passes_guard?(subject)
      @guard.passes?(subject)
    end

    #
    # Returns the transition for the given state, if one exists.
    def transition_for(subject, state)
      transitions_by_from = @transitions_by_from[state]

      return nil unless transitions_by_from

      transitions_by_from.find { |t| t.eligible?(subject, state) }
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
