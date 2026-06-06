require_relative 'switchboard/errors'
require_relative 'switchboard/hookable'
require_relative 'switchboard/transition'
require_relative 'switchboard/callable'
require_relative 'switchboard/guard'
require_relative 'switchboard/state'
require_relative 'switchboard/event'
require_relative 'switchboard/machine'

# Structure:
#   Machine is the container, built once per host class. It holds a set of
#   States and Events declared by the host class. Each State owns its
#   callbacks while each Event owns its transitions plus its callbacks. State and
#   Event both include the Callbacks module, which gives them a registry of
#   { hook => [callables] }. The firing order is static and lives in Callbacks::ORDER.
#
# Execution:
#   Calling an event method calls Machine#fire. It finds a transition
#   matching the current state (if no match it returns false and nothing happens).
#   On a match it iterates over Callbacks::ORDER and runs the owner's callbacks for each hook. Owner in this
#   context is the State or Event that owns the hook.
#   @state is swapped partway through the iteration, so exit hooks see the old state and enter hooks the new.
module Switchboard
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def switchboard(&block)
      machine = Machine.new

      machine.instance_eval(&block)

      machine.define_helpers_on(self)
    end
  end
end
