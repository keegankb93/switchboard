module Switchboard
  #
  # Holds a set of conditions that can be checked against a subject.
  class Guard
    def initialize(if_cond: nil, unless_cond: nil)
      @if = Array(if_cond)
      @unless = Array(unless_cond)
    end

    #
    # Check to see if the guard's conditions pass for the given subject.
    # @param subject [Object] The object to pass to the guard's conditions.
    def passes?(subject)
      # There might be a better way to do this, but this works for now
      @if.all?  { |c| Callable.resolve(subject, c) } && @unless.none? { |c| Callable.resolve(subject, c) }
    end
  end
end
