module Switchboard
  #
  # The machine class glues together and conducts the state transitions for the class switchboard is included in.
  class Machine
    def initialize
      @states = {}
      @events = {}
      @initial_state = nil
    end

    #
    # Registers a state with the Machine
    #
    # @param name [Symbol] The name of the state
    # @param initial [Boolean] Whether the state should be the initial state
    # @yield [State] yields the state object to configure callbacks
    def state(name, initial: false, &block)
      state = State.new(name)
      state.instance_eval(&block) if block

      @states[name] = state

      return unless initial

      raise Switchboard::Errors::InitialStateExistsError, @initial_state if @initial_state

      @initial_state = name
    end

    #
    # Registers an event with the Machine
    #
    # @param name [Symbol] The name of the event
    # @yield [Event] yields the event object to configure transitions
    def event(name, **opts, &block)
      event = Event.new(name, guard: Guard.new(if_cond: opts[:if], unless_cond: opts[:unless]))

      event.instance_eval(&block)

      @events[name] = event
    end

    #
    # Defines helper methods to manage state easier (follows AASMs predicates)
    #
    # @param klass [Class] The class to define the helper methods on i.e. Player etc.
    #
    # define_helpers_on(Player)
    # idling? -> true/false
    # idle -> fires the idle event
    def define_helpers_on(klass)
      machine = self

      #
      # Define predicate methods for each state
      # :idling? -> true/false
      @states.each_key do |state|
        klass.define_method("#{state}?") do
          current_state == state
        end
      end

      #
      # Define event methods for each event
      # :idle -> fires the idle event
      @events.each do |name, event|
        klass.define_method(name) do
          machine.fire(self, event)
        end
      end

      #
      # Define the current_state method
      # current_state -> the current state of the machine
      initial = @initial_state
      klass.define_method(:current_state) do
        @current_state ||= initial
      end
    end

    #
    # Fires an event on a subject, triggering state transitions and callbacks.
    #
    # @param subject [Object] the object whose state machine is firing the event
    # @param event [Event] the event to fire
    # @return [Boolean] true if the event was successfully fired, false otherwise
    def fire(subject, event)
      return false unless event.passes_guard?(subject)

      from = subject.current_state
      transition = event.transition_for(subject, from)

      return false unless transition

      # We need to keep track of both old state and new state so that
      # callbacks can operate on their respective states.
      old_state = @states[from]
      new_state = @states[transition.to]

      transition_context = { event: event, old_state: old_state, new_state: new_state }

      Hookable::ORDER.each do |step|
        run_all(subject, transition_context[step[:owner]], step[:hook])

        next unless step[:hook] == Hookable::STATE_CHANGE_AFTER

        subject.instance_variable_set(:@current_state, transition.to)
      end

      true
    rescue StandardError => e
      raise Switchboard::Errors::EventFireError, e
    end

    private

    #
    # Runs all callbacks for a given hook on the owning object (Event or State).
    #
    # @param subject [Object] the object whose state machine is running the callbacks
    # @param owner [Object] the owner of the hook (Event or State)
    # @param hook [Symbol] the hook to run callbacks for
    # @param args [Array] the arguments to pass to the callbacks
    # @return [void]
    def run_all(subject, owner, hook, *args)
      return unless owner

      owner.hooks_for(hook).each do |cb|
        Callable.resolve(subject, cb, *args)
      end
    end
  end
end
