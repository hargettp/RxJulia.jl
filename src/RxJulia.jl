module RxJulia

export 
    @rx, Reactor, slot, Event, ValueEvent, CompletedEvent,
    ErrorEvent, Observer, Observable, collect

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
`Observers` is a collection of subscribed `Observer`s
"""
Observers = Array{Observer,1}

mutable struct Observable
    observers::Observers
end

"""
A `Reactor` is an `Observer` that is also useful for building `Observer`s that
are `Observable` as well.
"""
mutable struct Reactor <: Observer
    op
    observable
end

# convert(Observable, reactor::Reactor) = reactor.observable


"""
Simply pass the value onto any observers
"""
function pass(observers, value)
    for observer in observers 
        onEvent(observer, value)
    end
end

Reactor() = Reactor(pass, [])

function getproperty(reactor::Reactor, field::Symbol)
    if field == :observers
        reactor.observers
    else
        getfield(reactor, field)
    end
end

"""
Deliver an `Event` to the `Observer`
"""
function onEvent(observer, event)
    if isa(event, ValueEvent)
        onValue(observer, event.value)
    elseif isa(event, CompletedEvent)
        onComplete(observer)
    else 
        onError(observer, event)
    end
end

function onValue(reactor::Reactor, value)
    reactor.op(reactor.observers, value)
end

"""
By default observers do nothing upon receiving a `CompletedEvent`
"""
function onComplete(observer::Observer)
end

"""
By default observers do nothing upon receiving an `ErrorEvent`
"""
function onError(observer::Observer, event::ErrorEvent)
end

"""
Notify the `Observer` that no more events will be received.
"""
function onComplete(reactor::Reactor)
    notify(reactor.observers) do observer
        onComplete(observer)
    end
end

"""
Notify the `Observer` that there was an error, and no more events will be received.
"""
function onError(reactor::Reactor, e)
    notify(reactor.observers) do observer
        onComplete(observer)
    end
end

"""
Subscribe an `Observer` to the given `Reactor`
"""
function subscribe!(observable::Observable, observer)
    push!(observable.observers, observer)
    observer
end

"""
Notify `Observer``` by invoking the block on each
"""
function notify(blk, observers, event)
    for observer in observers
        blk(observer, event)
    end
end

"""
Subscribe the `observer` to the `observable`, and return the `observable`.
"""
function chain!(observable, observer)
    subscribe!(observable, observer)
    observable
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
        if typeof(p) == Expr
            :( it = chain!($p, it) )
        else
            p
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

# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 
#
# Operators for creating new types of `Observable`s
#
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 

"""
Create a `Reactor` useful as the initial `Observable` in a reactive pipeline.
"""
function slot(initial)
    Reactor(pass, [], initial)
end

function setSlotValue(s, value)
    s.state = value
    onEvent(s.reactor, getSlotValue(s))
end

function getSlotValue(s)
    s.state
end

"""
Return an `Observer` that accumulates events on a `Channel`, which then may be
retrieved for iteration
"""

struct EventCollector <: Observer
    events::Channel
end

function events()
    EventCollector(Channel(32))
end

function onEvent(collector::EventCollector, event::Event)
    put!(collector.events, event)
end

function onComplete(collector::EventCollector)
    close(collector.events)
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
Treat an `Array` as an `Observable`
"""
function subscribe!(observable::Array, observer)
    @async begin 
        for item in observable
            onEvent(observer, ValueEvent(item))
        end
        onComplete(observer)
    end
end

end # module
