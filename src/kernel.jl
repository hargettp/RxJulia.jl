export 
    @rx, react, dispatch, Event, ValueEvent, CompletedEvent,
    ErrorEvent, Observer, Observable, events,
    onEvent, onValue, onComplete, onError, subscribe!, notify!, dispatch!

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
    dispatch!(observer, event)
end

"""
Dispatch an `Event` received at an `Observer`
"""
function dispatch!(observer, event)
    if isa(event, ValueEvent)
        onValue(observer, event.value)
    elseif isa(event, CompletedEvent)
        onComplete(observer)
    else 
        onError(observer, event)
    end
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

"""
Simply pass the value onto any observers
"""
function pass(observers, value)
    for observer in observers 
        onEvent(observer, value)
    end
end

Reactor() = Reactor(pass)
Reactor(fn) = Reactor(fn, [])

"""
Return a `Reactor` around the provided function, thus producing an `Observable`
that can also be an `Observer` of other `Observable`s.
"""
react(fn) = Reactor(fn)

function onValue(reactor::Reactor, value)
    reactor.fn(reactor.observers, value)
end

"""
Notify the `Observer` that no more events will be received.
"""
function onComplete(reactor::Reactor)
    for observer in reactor.observers
        onComplete(observer)
    end
end

"""
Notify the `Observer` that there was an error, and no more events will be received.
"""
function onError(reactor::Reactor, e)
    for observer in reactor.observers
        onComplete(observer)
    end
end

function subscribe!(reactor::Reactor, observer)
    subscribe!(reactor.observers, observer)
end

"""
A `Dispatcher` evaluates received `Event` with a function and 
emits them onward as necessary to its `Observers`
"""
struct Dispatcher <: Observer
    fn
    observers::Observers
end

Dispatcher() = Dispatcher(notify!)
Dispatcher(fn) = Dispatcher(fn, [])

"""
Return a `Dispatcher` that uses the supplied block to dispatch `Event`s
"""
dispatch(fn) = Dispatcher(fn)

function onEvent(dispatcher::Dispatcher, event::Event)
    dispatcher.fn(dispatcher.observers, event)
end

function onValue(dispatcher::Dispatcher, value)
    onEvent(dispatcher, ValueEvent(value))
end

function onError(dispatcher::Dispatcher, err)
    onEvent(dispatcher, ErrorEvent(err))
end

function onComplete(dispatcher::Dispatcher)
    onEvent(dispatcher, CompletedEvent())
end

function subscribe!(dispatcher::Dispatcher, observer)
    subscribe!(dispatcher.observers, observer)
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
end

function onValue(collector::EventCollector, value)
    onEvent(collector, ValueEvent(value))
end

function onComplete(collector::EventCollector)
    close(collector.events)
end

function onError(collector::EventCollector, e)
    put!(collector.events, ErrorEvent(e))
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
            onComplete(observer)
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
            onComplete(observer)
        catch e
            println(stderr, "Caught error $e)")
            for (exc, bt) in Base.catch_stack()
                showerror(stdout, exc, bt)
                println()
            end            
        end
    end
end

