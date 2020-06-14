export select, reject, fmap, take, keep, drop, cut, distinct, span, merge, zip

using DataStructures
using Base.Threads: Atomic, atomic_sub!

# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 
#
# Various types of operators for creating new `Observable`s
#
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 

"""
    select(fn::Function)

Apply a filter function such that only values for which the function returns
true will be passed onto [`Observer`](@ref)s
"""
function select(fn::Function)
  react() do observers, value
    if fn(value)
      evt = ValueEvent(value)
      notify!(observers, evt)
    end
  end
end

"""
    reject(fn::Function)::Reactor

Apply a filter function such that only values for which the function returns
false will be passed onto [`Observer`](@ref)s
"""
function reject(fn::Function)::Reactor
  react() do observers, value
    if !fn(value)
      evt = ValueEvent(value)
      notify!(observers, evt)
    end
  end
end

"""
    fmap(fn::Function)

Apply function to all observed values, and emit the result. Functional equivalent of `map`.

"""
function fmap(fn::Function)
  react() do observers, value
    evt = ValueEvent(fn(value))
    notify!(observers, evt)
  end
end

"""
    take(n)

Take only the first n values, discarding the rest. If less than n values observed,
emit only values observed.
"""
function take(n)
  let counter = n
    react() do observers, value
      counter -= 1
      if counter >= 0
        notify!(observers, ValueEvent(value))
      end
    end
  end
end

"""
    keep(n)

Keep only the last n values, discarding the rest. If less than n values observed,
emit only values observed.
"""
function keep(n)
  let backlog = Queue{Any}()
    dispatch() do observers, evt
      if isa(evt, ValueEvent)
        enqueue!(backlog, evt)
        if length(backlog) > n
          dequeue!(backlog)
        end
      elseif isa(evt, CompletedEvent)
        for evt in backlog
          notify!(observers, evt)
        end
        complete!(observers)
      else
        notify!(observers, evt)
      end
    end
  end
end

"""
    drop(n)

Drop the first n events observed, emitting all others that precede them. If less than n 
events observed, emit nothing.
"""
function drop(n)
  let counter = n
    react() do observers, value
      if counter > 0
        counter -= 1
      else
        notify!(observers, ValueEvent(value))
      end
    end
  end
end

"""
    cut(n)

Drop the last n events observed, emitting all others that precede them. If less than n 
events observed, emit nothing.
"""
function cut(n)
  let backlog = Queue{Any}()
    counter = n
    react() do observers, value
      enqueue!(backlog, value)
      if counter > 0
        counter -= 1
      else
        val = dequeue!(backlog)
        notify!(observers, ValueEvent(val))
      end
    end
  end
end

"""
    distinct()

Only emit unique values observed
"""
function distinct()
  let values = Set([])
    react() do observers, value
      if !(value in values)
        union!(values, Set([value]))
        notify!(observers, ValueEvent(value))
      end
    end
  end
end

"""
    span(m, n)

Emit only the integers in the range of m to n, inclusive
"""
function span(m, n)
  collect(range(m, length = (n - m + 1)))
end

struct Merge
  closeCount::Atomic{Int}
  collector::Collector
end

Merge(observables) = Merge(Atomic{Int}(length(observables) - 1), events())

function onEvent(merger::Merge, event::Event)
  if isa(event, CompletedEvent)
    count = atomic_sub!(merger.closeCount, 1)
    if count <= 0
      put!(merger.collector.events, event)
      close(merger.collector.events)
    end
  else
    put!(merger.collector.events, event)
    if isa(event, ErrorEvent)
      close(merger.collector.events)
    end
  end
end

function subscribe!(merger::Merge, observer)
  subscribe!(merger.collector, observer)
end

"""
    merge(observables...)

Produce an [`Observable`](@ref) that emits from the supplied [`Observable`](@ref)s,
until either all have emitted a [`CompletedEvent`](@ref) or one of them emits 
an [`ErrorEvent`](@ref)
"""
function merge(observables...)
  let merger = Merge(observables)
    for observable in observables
      @async begin
        subscribe!(observable, merger)
      end
    end
    merger
  end
end

"""
    zip(observables...)

Given one or more [`Observable`](@ref)s, read one value at a time from each
and collect into a `Tuple`, stopping when either there is an [`ErrorEvent`](@ref)
or any [`CompletedEvent`](@ref)
"""
function zip(observables...)
    collectors = map(observables) do observable
        @rx() do
            observable
        end
    end
    Base.Iterators.zip(collectors...)
end