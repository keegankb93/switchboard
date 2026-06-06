module Switchboard
  module Callable
    extend self

    #
    # Resolves a callable on a subject, passing the given arguments.
    #
    # @param subject [Object] The object to call the method on.
    # @param callable [Symbol, Proc, Object] The callable to resolve.
    # @param args [Array] The arguments to pass to the callable.
    # @return [void] Not really meant to be consumed
    def resolve(subject, callable, *args)
      case callable
      when Symbol then subject.send(callable, *args)
      when Proc then subject.instance_exec(*args, &callable)
      else callable.call(subject, *args)
      end
    end
  end
end
