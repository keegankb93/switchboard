module Switchboard
  #
  # Implements hook handling for a State or Event.
  module Hookable
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
