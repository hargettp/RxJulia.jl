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
  collector,
  onEvent,
  subscribe!,
  chain!,
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
Observers = Vector{Observer}

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

Notify [`Observer`](@ref) by invoking the block on each
"""
function notify!(observers, event)
  for observer in observers
    onEvent(observer, event)
  end
end

"""
    error!(observers, err)

Emit an [`ErrorEvent`](@ref) to [`Observers`](@ref)
"""
function error!(observers, err)
  evt = ErrorEvent(err)
  notify!(observers, evt)
end

"""
    complete!(observers)

Emit a [`CompletedEvent`](@ref) to [`Observers`](@ref)
"""
function complete!(observers)
  evt = CompletedEvent()
  notify!(observers, evt)
end

"""
    subscribe!(observable::Observable, observer)

Subscribe an [`Observer`](@ref) to the given [`Observable`](@ref), return the [`Observer`](@ref)
"""
function subscribe!(observable::Observable, observer)
  register!(observable.observers, observer)
end

"""
    register!(observers::Observers, observer)
Add an [`Observer`](@ref) to an existing set of [`Observers`](@ref), return the [`Observer`](@ref)
"""
function register!(observers::Observers, observer)
  push!(observers, observer)
  observer
end

"""
    chain!(observable, observer)

Subscribe the [`Observer`](@ref) to the [`Observable`](@ref) using [`subscribe!`](@ref), 
and return the [`Observable`](@ref).
"""
function chain!(observable, observer)
  subscribe!(observable, observer)
  observable
end

"""
    Reactor() = Reactor(notify!)
    Reactor(fn) = Reactor(fn, [])

A `Reactor` is an [`Observer`](@ref) that is also useful for building [`Observer`](@ref)s that
are [`Observable`](@ref) as well.

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

Return a [`Reactor`](@ref) around the provided function which takes [`Observers`](@ref) 
and an [`Event`](@ref), taking action as appropriate, and producing an [`Observable`](@ref)
that can also be an [`Observer`](@ref) of other [`Observable`](@ref)s.
"""
dispatch(fn::Function)::Reactor = Reactor(fn)

"""
    react(fn::Function)::Reactor
Return a [`Reactor`](@ref) around the provided function which takes [`Observers`](@ref) 
and a value, taking action as appropriate, and producing an [`Observable`](@ref)
that can also be an [`Observer`](@ref) of other [`Observable`](@ref)s. [`CompletedEvent`](@ref)s
and [`ErrorEvent`](@ref)s are passed on to [`Observers`](@ref), while [`ValueEvent`](@ref)s
are passed to the supplied function. The supplied function takes [`Observers`](@ref) and a value
as arguments.
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
  register!(reactor.observers, observer)
end

"""
An [`Observer`](@ref) that accumulates events on a `Channel`, which then may be
retrieved for iteration
"""
struct Collector <: Observer
  events::Channel
end

"""
    collector(buffer = 0)
Return a [`Collector`](@ref) to accumulate observed [`Event`](@ref)s. If set to a value
greater than 0, then events will be buffered with a `Channel` with the specified buffer size,
throttling incoming events until the channel has empty slots.
"""
function collector(buffer = 0)
  Collector(Channel(buffer))
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
    rx(blk,source=nothing; buffer=0)

Given a do-block where each statement is an [`Observable`](@ref), 
[`subscribe!`](@ref) to each in sequence to the one proceeding using [`chain!`](@ref). 
Return an object that one can use to iterate over the events from
the last [`Observable`](@ref) in the block. 

If source (a positional argument) is provided and is not `nothing`, then it is used as the 
initial  [`Observable`](@ref) in the pipeline; this can be useful if the result of one 
pipeline needs to be fed into another pipeline as the initial [`Observable`](@ref).

The value of `buffer` (a keyword argument is passed to [`collector`](@ref) in order to 
create a potentially buffered `Channel` for the [`Collector`](@ref) at 
the end of the pipeline.

Example:

```@example
results = @rx() do
count
filter(:even)
end
printlin([result for result in results])
```
"""
macro rx(args...)
  # the blk is actually an expression of type :-> (closure),
  # and its first arg is the args list (should be () ), followed by
  # the array of statements in the closure's block
  blk, posargs, kwargs = macroArguments(args)
  buffer = get(kwargs, :buffer, 0)
  source = if length(posargs) >= 1
    posargs[1]
  else
    :nothing
  end
  steps = Vector(reverse(blk.args[2].args))
  if source !== :nothing
    push!(steps, source)
  end
  pipes = map(steps) do p
    if isa(p, LineNumberNode)
      p
    else
      :(it = chain!($(esc(p)), it))
    end
  end
  return quote
    let evts = collector($(esc(buffer)))
      begin
        it = evts
        $(pipes...)
      end
      evts
    end
  end
end


"""
    generate_value!(value, observer)

Treat a value as an [`Observable`](@ref), emitting the value followed by a [`CompletedEvent`](@ref)
"""
function generate_value!(value, observer)
  @async begin
    try
      evt = ValueEvent(value)
      onEvent(observer, evt)
      onEvent(observer, CompletedEvent())
    catch e
      println(stderr, "Caught error $e")
      for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
      end
      onEvent(observer, ErrorEvent(e))
    end
  end
end

"""
    generate_iterable!(iterable, observer)

Treat an iteraable as an [`Observable`](@ref), emitting each of its elements in turn 
in a [`ValueEvent`](@ref), and concluding with a [`CompletedEvent`](@ref).
"""
function generate_iterable!(iterable, observer)
  @async begin
    try
      for item in iterable
        evt = ValueEvent(item)
        onEvent(observer, evt)
      end
      onEvent(observer, CompletedEvent())
    catch e
      println(stderr, "Caught error $e")
      for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
      end
      onEvent(observer, ErrorEvent(e))
    end
  end
end

function generate!(observable, observer)
  if applicable(iterate, observable)
    generate_iterable!(observable, observer)
  else
    generate_value!(observable, observer)
  end
end

function generate!(value::String, observer)
  generate_value!(value, observer)
end

"""
Treat any value as an [`Observable`](@ref), and subscribe the [`Observer`](@ref) to it; the value
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
# works for integers
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
function subscribe!(observable, observer)
  generate!(observable, observer)
  observer
end
