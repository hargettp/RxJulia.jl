export @rx,
  react,
  dispatch,
  Event,
  ValueEvent,
  CompletedEvent,
  ErrorEvent,
  Observer,
  Observable,
  Reactor,
  events,
  onEvent,
  subscribe!,
  notify!,
  Collector

# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 
#
# Core objects for implementing a reactive programming model
# (inspired by ReactiveX)
#
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 

"""
An [`Event`](@ref) containing a value to deliver to an [`Observable`](@ref).
"""
struct ValueEvent{T}
  value::T
end

"""
An [`Event`](@ref) signifying no more events are available from the originating
[`Observable`](@ref).
"""
struct CompletedEvent end

"""
An [`Event`](@ref) signifying the originating [`Observable`](@ref) encountered an error;
no more events will be delivered after events of tyie.
"""
struct ErrorEvent{E}
  error::E
end

"""
An `Event` is any of the following:
* A _value_, encapsulated as [`ValueEvent`](@ref)
* A _completion_ event, encapsulated as [`CompletedEvent`](@ref)
* An _error_, encapsulated as [`ErrorEvent`](@ref)
"""
Event = Union{ValueEvent,CompletedEvent,ErrorEvent}

"""
An `Observer` is a receiver of [`Event`](@ref)s via [`onEvent`](@ref)
"""
abstract type Observer end

"""
    onEvent(observer, event)

Deliver an [`Event`](@ref) to the `Observer`
"""
function onEvent(observer, event) end

"""
`Observers` is a collection of subscribed [`Observer`](@ref)s
"""
Observers = Array{Observer,1}

"""
An `Observable` is a source of [`Event`](@ref)s, with [`Observer`](@ref)s 
[`subscribe!`](@ref)ing to the `Observable` in order to receive those events. 

See [Observable in ReactiveX documentation](http://reactivex.io/documentation/observable.html)
"""
mutable struct Observable
  observers::Observers
end

Observable() = Observable([])

"""
    notify!(observers, event)

Notify `Observer` by invoking the block on each
"""
function notify!(observers, event)
  for observer in observers
    onEvent(observer, event)
  end
end

"""
    error!(obserers, err)

Emit an `ErrorEvent` to `Observers`
"""
function error!(obserers, err)
  evt = ErrorEvent(err)
  notify!(obserers, evt)
end

"""
    complete!(observers)

Emit a `CompletedEvent` to `Observers`
"""
function complete!(observers)
  evt = CompletedEvent()
  notify!(observers, evt)
end

"""
    subscribe!(observable::Observable, observer)

Subscribe an [`Observer`](@ref) to the given `Observable`, return the [`Observer`](@ref)
"""
function subscribe!(observable::Observable, observer)
  subscribe!(observable.observers, observer)
end

"""
    subscribe!(observers::Observers, observer)
Add an [`Observer`](@ref) to an existing set of `Observers`, return the [`Observer`](@ref)
"""
function subscribe!(observers::Observers, observer)
  push!(observers, observer)
  observer
end

"""
    chain!(observable, observer)

Subscribe the [`Observer`](@ref) to the `Observable`, and return the [`Observable`](@ref).
"""
function chain!(observable, observer)
  subscribe!(observable, observer)
  observable
end

"""
    Reactor() = Reactor(notify!)
    Reactor(fn) = Reactor(fn, [])

A `Reactor` is an [`Observer`](@ref) that is also useful for building [`Observer`](@ref)s that
are `Observable` as well.

A `Reactor` is the analogue of a [`Subject`](http://reactivex.io/documentation/subject.html) in the ReactiveX model.
"""
mutable struct Reactor <: Observer
  """
  Function with arguments `(observers::Observers, value)` to handle
  each `ValueEvent` for the `Reactor`.
  """
  fn::Any
  """
  The `Observers` subscribed to this `Reactor`
  """
  observers::Observers
end

Reactor() = Reactor(notify!)
Reactor(fn) = Reactor(fn, [])

"""
    dispatch(fn::Function)::Reactor = Reactor(fn)

Return a `Reactor` around the provided function which takes [`Observers`](@ref) and an [`Event`](@ref),
taking action as appropriate, and producing an [`Observable`](@ref)
that can also be an [`Observer`](@ref) of other [`Observable`](@ref)s.
"""
dispatch(fn::Function)::Reactor = Reactor(fn)

"""
    react(fn::Function)::Reactor
Return a `Reactor` around the provided function which takes `Observers` and a value,
taking action as appropriate, and producing an `Observable`
that can also be an [`Observer`](@ref) of other `Observable`s. `CompletedEvent`s and `ErrorEvent`s
are passed on to `Observers`, while `ValueEvent`s are passed to the supplied function.
The supplied funciton takes `Observers` and a `value` as arguments.
"""
react(fn::Function)::Reactor =
  dispatch() do observers::Observers, event::Event
    if isa(event, ValueEvent)
      fn(observers, event.value)
    else
      notify!(observers, event)
    end
  end

function onEvent(reactor::Reactor, event::Event)
  reactor.fn(reactor.observers, event)
end

function subscribe!(reactor::Reactor, observer)
  subscribe!(reactor.observers, observer)
end

"""
An [`Observer`](@ref) that accumulates events on a `Channel`, which then may be
retrieved for iteration
"""
struct Collector <: Observer
  events::Channel
end

"""
    events(sz = 32)
Return a `Collector` to accumulate observed [`Event`](@ref)s
"""
function events(sz = 32)
  Collector(Channel(sz))
end

function onEvent(collector::Collector, event::Event)
  put!(collector.events, event)
  if !isa(event, ValueEvent)
    close(collector.events)
  end
end

function Base.iterate(collector::Collector, _s = nothing)
  evt = try
    # We have to catch an exception in case the channel i closed
    take!(collector.events)
  catch e
    if isa(e, InvalidStateException)
      return nothing
    else
      throw(e)
    end
  end
  if isa(evt, CompletedEvent)
    nothing
  elseif isa(evt, ValueEvent)
    return (evt.value, collector)
  elseif isa(evt, ErrorEvent)
    throw(evt.error)
  else
    error("Unknown event $show(evt)")
  end
end

function Base.IteratorSize(collector::Collector)
  Base.SizeUnknown()
end

"""
    rx(blk)

Given a do-block where each statement is an `Observable`, 
`subscribe!` each in sequence to the one proceeding. Return an
object that one can use to iterate over the events from
the last `Observable` in the block.

Example:

```@example
results = @rx() do
count
filter(:even)
end
for evt in results
# do something with evt
end
```
"""
macro rx(blk)
  # the blk is actually an expression of type :-> (closure),
  # and its first arg is the args list (should be () ), followed by
  # the array of statements in the closure's block
  steps = reverse(blk.args[2].args)
  pipes = map(steps) do p
    if typeof(p) == LineNumberNode
      p
    else
      :(it = chain!($(esc(p)), it))
    end
  end
  return quote
    let collector = events()
      it = collector
      $(pipes...)
      collector
    end
  end
end


"""
    subscribe_value!(value, observer)

Treat a value as an [`Observable`](@ref), emitting the value followed by a [`CompletedEvent`](@ref)
"""
function subscribe_value!(value, observer)
  begin
    try
      evt = ValueEvent(value)
      onEvent(observer, evt)
      onEvent(observer, CompletedEvent())
    catch e
      println(stderr, "Caught error $e)")
      for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
      end
    end
  end
end

"""
    subscribe_iterable!(iterable, observer)
    
Treat an iteraable as an `Observable`, emitting each of its elements in turn in a [`ValueEvent`](@ref),
and concluding with a [`CompletedEvent`](@ref).
"""
function subscribe_iterable!(iterable, observer)
  begin
    try
      for item in iterable
        evt = ValueEvent(item)
        onEvent(observer, evt)
      end
      onEvent(observer, CompletedEvent())
    catch e
      println(stderr, "Caught error $e)")
      for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
      end
    end
  end
end

"""
Treat any value as an `Observable`, and subscribe the [`Observer`](@ref) to it; the value
will be emitted once with a [`ValueEvent`](@ref), then a [`CompletedEvent`](@ref) will be emitted. If the
value is iterable (e.g., `applicable(iterate, value)` returns `true`), then emit
over each value returned by the iterable and pass on to the [`Observer`](@ref), concluding
with a [`CompletedEvent`](@ref). Note that strings are treated as an atomic value and not 
an iterable.

```jldoctest
# works for booleans
julia> evts = @rx(() -> true)
Collector(Channel{Any}(sz_max:32,sz_curr:2))

julia> collect(evts)
1-element Array{Any,1}:
 true
```

```jldoctest
# works for booleans
julia> evts = @rx( ()-> 1 )
Collector(Channel{Any}(sz_max:32,sz_curr:2))

julia> collect(evts)
1-element Array{Any,1}:
 1
```

```jldoctest
# works for strings
julia> evts = @rx( ()-> "foo" )
Collector(Channel{Any}(sz_max:32,sz_curr:2))

julia> collect(evts)
1-element Array{Any,1}:
 "foo"
```

```jldoctest
# works for iterables
julia> evts = @rx( ()-> [1 2 3] )
Collector(Channel{Any}(sz_max:32,sz_curr:4))

julia> collect(evts)
3-element Array{Any,1}:
 1
 2
 3
```
"""
function subscribe!(value, observer)
  if applicable(iterate, value)
    subscribe_iterable!(value, observer)
  else
    subscribe_value!(value, observer)
  end
end

function subscribe!(value::String, observer)
  subscribe_value!(value, observer)
end