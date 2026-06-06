module Switchboard
  #
  # Implements hook handling for a State or Event.
  module Hookable
    #
    # Defines the order in which callbacks are run.
    # This is the same general order in the AASM library and a good reference
    # https://github.com/aasm/aasm#lifecycle
    # Owner here is the object that owns the hook method (State or Event)
    ORDER = [
      { owner: :event, hook: :before },
      { owner: :old_state, hook: :before_exit },
      { owner: :old_state, hook: :after_exit },
      { owner: :new_state, hook: :before_enter },
      { owner: :new_state, hook: :after_enter },
      { owner: :event, hook: :after }
    ].freeze

    # This is when we change what state we're operating Open3
    # So after_exit and anything before it will operate on the OLD STATE
    # then anything after it will operate on the NEW STATE
    STATE_CHANGE_AFTER = :after_exit

    #
    # Registry of hooks
    # Default entry is an empty array, so `hooks[hook]` always returns an array.
    # @hooks is a list of callables keyed by hook name with an array of callables.
    def hooks
      @hooks ||= Hash.new { |h, k| h[k] = [] }
    end

    # Register a hook with the given name.
    #
    # @param name [Symbol] the name of the hook to register.
    # @param callable [Proc, nil] the callable to register, or nil to use a block.
    # @yield the block to register, if no callable is provided.
    def on(name, callable = nil, &block)
      (hooks[name] || []) << (block || callable)
    end

    # Get the hooks for the given name.
    # Returns an array of callables for the given hook, or an empty array if none are registered.
    #
    # @param name [Symbol] the name of the hook to get.
    # @return [Array] an array of callables for the given hook, or an empty array if none are registered.
    def hooks_for(name)
      hooks[name] || []
    end
  end
end
