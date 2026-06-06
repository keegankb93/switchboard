module Switchboard
  #
  # Represents a state and its transitions
  class State
    include Hookable

    attr_reader :name

    def initialize(name)
      @name = name
    end

    # We could be fancy here and just define_methods, but let's be explicit for now.

    def before_enter(m = nil, &block)
      on(:before_enter, m, &block)
    end

    def after_enter(m = nil, &block)
      on(:after_enter, m, &block)
    end

    def before_exit(m = nil, &block)
      on(:before_exit, m, &block)
    end

    def after_exit(m = nil, &block)
      on(:after_exit, m, &block)
    end
  end
end
