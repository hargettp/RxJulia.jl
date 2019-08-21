export 
    @rx, react, dispatch, Event, ValueEvent, CompletedEvent,
    ErrorEvent, Observer, Observable, events,
    onEvent, subscribe!, notify!

# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 
#
# Core objects for implementing a reactive programming model
# (inspired by ReactiveX)
#
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 

struct ValueEvent{T}
    value::T
end

struct CompletedEvent
end

struct ErrorEvent{E}
    error::E
end

"""
An `Event` is any of the following:
* A _value_, encapsulated as `ValueEvent`
* A _completion_ event, encapsulated as `CompletedEvent`
* An _error_, encapsulated as `ErrorEvent`
"""
Event = Union{ValueEvent,CompletedEvent,ErrorEvent}

"""
An `Observer` is a receiver of `Event`s via `onEvent`
"""
abstract type Observer end

"""
Deliver an `Event` to the `Observer`
"""
function onEvent(observer, event)
end

"""
`Observers` is a collection of subscribed `Observer`s
"""
Observers = Array{Observer,1}

"""
An `Observable` is a source of `Event`s, with `Observer`s 
`subscribe!`ing to the `Observable` in order to receive those events.
"""
mutable struct Observable
    observers::Observers
end

Observable() = Observable([])

"""
Notify `Observer` by invoking the block on each
"""
function notify!(observers, event)
    for observer in observers
        onEvent(observer, event)
    end
end

"""
Emit an `ErrorEvent` to `Observers`
"""
function error!(obserers, err)
    evt = ErrorEvent(err)
    notify!(obserers, evt)
end

"""
Emit a `CompletedEvent` to `Observers`
"""
function complete!(observers)
    evt = CompletedEvent()
    notify!(observers, evt)
end

"""
Subscribe an `Observer` to the given `Observable`
"""
function subscribe!(observable::Observable, observer)
    subscribe!(observable.observers, observer)
end

"""
Add an `Observer` to an existing set of `Observers`
"""
function subscribe!(observers::Observers, observer)
    push!(observers, observer)
    observer
end

"""
Subscribe the `Observer` to the `Observable`, and return the `Observable`.
"""
function chain!(observable, observer)
    subscribe!(observable, observer)
    observable
end

"""
A `Reactor` is an `Observer` that is also useful for building `Observer`s that
are `Observable` as well.
"""
mutable struct Reactor <: Observer
    """
    Function with arguments `(observers::Observers, value)` to handle
    each `ValueEvent` for the `Reactor`.
    """
    fn
    """
    The `Observers` subscribed to this `Reactor`
    """
    observers::Observers
end

Reactor() = Reactor(notify!)
Reactor(fn) = Reactor(fn, [])

"""
Return a `Reactor` around the provided function, thus producing an `Observable`
that can also be an `Observer` of other `Observable`s.
"""
dispatch(fn) = Reactor(fn)
react(fn) = dispatch() do observers, event
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
An `Observer` that accumulates events on a `Channel`, which then may be
retrieved for iteration
"""
struct EventCollector <: Observer
    events::Channel
end

"""
Return an `EventCollector` to accumulate observed `Event`s
"""
function events(sz = 32)
    EventCollector(Channel(sz))
end

function onEvent(collector::EventCollector, event::Event)
    put!(collector.events, event)
    if !isa(event, ValueEvent)
        close(collector.events)
    end
end

function Base.iterate(collector::EventCollector, _s = nothing)
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

function Base.IteratorSize(collector::EventCollector)
    Base.SizeUnknown()
end

"""
Given a do-block where each statement is an `Observable`, 
`subscribe!` each in sequence to the one proceeding. Return an
object that one can use to iterate over the events from
the last `Observable` in the block.

Example:

  ```
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
            :( it = chain!($(esc(p)), it) )
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
Treat any value as an `Observable`, and subscribe the `Observer` to it; the value
will be emitted once with a `ValueEvent`, then a `CompletedEvent` will be emitted.
"""
function subscribe!(value, observer)
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
Treat an `Array` as an `Observable`, emitting each of its elements in turn in a `ValueEvent`,
and concluding with a `CompletedEvent`.
"""
function subscribe!(observable::Array, observer)
    begin 
        try
            for item in observable
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

