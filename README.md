# Switchboard

A simple state machine library for DragonRuby that is based on the [AASM](https://github.com/aasm/aasm) DSL.

>[!NOTE]
> I've used AASM in my professional career and when working in DragonRuby I found myself thinking about the DSL AASM provided and how it would be a good fit in DragonRuby. Switchboard borrows AASM's DSL, but is a minimal implementation built for DragonRuby as AASM is built for Rails/ActiveRecord, that being said it is not an exact 1:1 DSL.

>[!WARNING]
> While I did write some "tests" to try and test all the features this still hasn't be put to the..test..so you may encounter some bugs
> please open up an issue or a PR!

## Quick start

```ruby
class Enemy
  include Switchboard

  switchboard do
    state :appearing, initial: true
    state :idling
    state :chasing

    event :idle do
      transition from: :appearing, to: :idling
    end

    event :chase do
      transition from: :idling, to: :chasing
    end
  end
end

enemy = Enemy.new
enemy.current_state   # => :appearing
enemy.appearing?      # => true
enemy.idle            # => true   (transitions appearing -> idling)
enemy.idling?         # => true
enemy.chase           # => true   (idling -> chasing)
enemy.idle            # => false  (no transition from chasing via :idle)
```

Including `Switchboard` gives the class a `switchboard` macro. Declaring
states and events generates helper methods on the class:

- `current_state` — the current state (defaults to the initial state)
- `<state>?` — a predicate per state, e.g. `idling?`
- `<event>` — a method per event that fires it, e.g. `chase`

## States

Each state is declared with `state`. Exactly one state should be marked
`initial: true` which is where the machine starts.

```ruby
state :sleeping, initial: true
state :running
state :finished
```

>[!NOTE]
>Declaring two initial states raises an error.

## Events and transitions

An event groups one or more transitions. Firing the event applies the first
transition whose `from` matches the current state (and whose guards pass — see
below). `from` accepts a single state or an array.

```ruby
event :sleep do
  transition from: %i[running cleaning], to: :sleeping
end
```

Firing returns `true` if a transition was applied, `false` if none matched.
A `false` return is not an error and simply means the event didn't apply from the
current state (or a guard blocked it).

```ruby
enemy.sleep   # => true if it transitioned, false if not
```

When several transitions could apply, the **first declared** one that's
eligible wins:

```ruby
event :react do
  transition from: :idling, to: :fleeing, if: :low_health?
  transition from: :idling, to: :chasing, if: :sees_player?
end
```

If both `low_health?` and `sees_player?` are true, the enemy flees, because
`:fleeing` is declared first.

## Guards

Guards conditionally allow or block a transition or an entire event. Use
`if:` (must be truthy) and `unless:` (must be falsey). A guard may be a symbol
(method name on the object), a proc, or an array of those (all must pass).

### Per-transition guards

```ruby
event :chase do
  transition from: :idling, to: :chasing, if: :sees_player?
end
```

### Event-level guards

An event-level guard gates the whole event and if it fails, no transition is considered.

```ruby
event :calm, if: :safe? do
  transition from: %i[chasing fleeing], to: :idling
end
```

### Combining and arrays

```ruby
event :advance, if: %i[ready? armed?], unless: :stunned? do
  transition from: :waiting, to: :attacking
end
```

`ready?` and `armed?` must both be truthy, and `stunned?` must be falsey.

## Callbacks (hooks)

Callbacks run at points around a transition. State callbacks fire on
enter/exit where event callbacks fire before/after the whole event.

>[!NOTE]
>This is where the main deviation in the DSL comes into play. Rather than keyword args in (AASM) they are methods within a block.

### State hooks

```ruby
state :idling do
  before_enter { puts "about to idle" }
  after_enter  { play_animation(:idle) }
  before_exit  { puts "leaving idle" }
  after_exit   { puts "left idle" }
end
```

### Event hooks

```ruby
event :chase do
  before { puts "preparing to chase" }
  transition from: :idling, to: :chasing
  after  { puts "chase applied" }
end
```

>[!NOTE]
> It doesn't matter where you put the before/after, this is simply registering them. So, if you have aesthetic issues like me, you can put the before before the transition and the after after the transition! Or if you hate aesthetics you can write them like below:

```ruby
event :chase do
  before { puts "preparing to chase" }
  after  { puts "chase applied" }
  transition from: :idling, to: :chasing
end
```

### Callback forms

Every hook (and every guard) accepts three forms:

```ruby
# 1. Symbol — calls the method on the object
state :idling do
  after_enter :play_idle
end

# 2. Proc - This is executed in the context of the object the state machine belongs to. So if you included this on Player, then Player is self.
state :idling do
  after_enter { play_animation(:idle) }
end

# 3. Callable object — anything responding to #call(subject)
module PlayIdle
  def self.call(subject) = subject.play_animation(:idle)
end

state :idling do
  after_enter PlayIdle
end
```

For the callable-object form, prefer a module with `self.call` for stateless
hooks. An instance (`SomeClass.new`) also works if you need the object to
carry state across transitions, though for game entities that state usually
belongs on the object itself, reached via a symbol callback.

### Firing order

For a single transition, hooks run in this order (modeled after AASMs lifecycles):

```
event       before
old state   before_exit
old state   after_exit
            --- state changes here ---
new state   before_enter
new state   after_enter
event       after
```

Anything up to and including `after_exit` sees the **old** state; everything
after sees the **new** state. So `before_exit`/`after_exit` run while still in
the source state, and `before_enter`/`after_enter` run once the machine has
switched.

## Example

```ruby
class Mob
  include Switchboard

  state_machine do
    state :appearing, initial: true
    state :idling do
      after_enter { play_animation(:idle_down_right) }
    end

    event :finish_appearing do
      transition from: :appearing, to: :idling
    end
  end

  def initialize
    play_animation(:appear)
  end

  def tick(args)
    # fire the event once the appear animation completes
    finish_appearing if appearing? && animation_finished?
  end
end
```

Here the `appear` animation plays on initialize. Each `tick`, once the appear animation
finishes, `finish_appearing` fires — the machine moves to `:idling` and the
`after_enter` hook starts the idle loop. Note the initial state's hooks do
**not** fire on construction; only transitions into a state run its enter
hooks.

## Notes and limits

- **Initial state isn't "entered."** The initial state is set lazily and its
  `before_enter`/`after_enter` hooks don't run at startup — only when a
  transition moves into it later.
- **A `false` return means "no transition," not "failure."** Check the return
  value if you need to know whether an event applied.

## Credits

- [AASM](https://github.com/aasm/aasm) for a well-thought DSL and a wonderful library for Rails.
- Konnor Rogers from the DragonRuby discord for the library name
