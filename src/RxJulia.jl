module RxJulia

export greet, @rx, Reactor, slot

greet() = print("hello, world!")

abstract type Observable end
abstract type Observer end

"""
A `Reactor` is an `Observable` that is also useful for building `Observer`s that
are `Observable` as well.
"""
mutable struct Reactor 
    op
    observers::Array{Any,1}
    state
end

Reactor() = Reactor(pass, [])

"""
Subscribe an `Observer` to the given `Observable`
"""
function subscribe!(reactor::Reactor, observer)
    push!(reactor.observers, observer)
    observer
end

"""
Deliver a value to the `Observer`
"""
function onEvent(reactor::Reactor, value)
    reactor.op(reactor, value)
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
        onError(observer, e)
    end
end

"""
Simply pass the value onto any observers
"""
function pass(reactor::Reactor, value)
    for observer in reactor.observers 
        onEvent(observer, value)
    end
end

"""
Ssubscribe the `observer` to the `observable`, and return the `observable`.
"""
function chain!(observable, observer)
    subscribe!(observable, observer)
    observable
end

"""
Given a do-block where each statement is an observable, 
subscribe each in sequence to the one proceeding.

Example:

  ```
  @rx() do
    count
    filter(:even)
  end`
  ```
"""
macro rx(blk)
    # the blk is actually an expression of type :-> (closure),
    # and its first args is the args list (should be () ), followed by
    # the array of statements in the closure's block
    steps = reverse(blk.args[2].args)
    last = steps[1]
    pipes = map(steps[2:end]) do p
        if typeof(p) == Expr
            :( it = chain!($p, it) )
        else
            p
        end
    end
    return quote
        let it = $last
            $(pipes...)
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
Return a `Reactor` that will invoke the provided function
"""

end # module
