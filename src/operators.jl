export select, reject, take, keep, drop, cut, distinct, span

using DataStructures

# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 
#
# Various types of operators for creating new `Observable`s
#
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 

"""
Apply a filter function such that only values for which the function returns
true will be passed onto [`Observer`](@ref)s
"""
function select(fn)
    react() do observers, value
        if fn(value)
            evt = ValueEvent(value)
            notify!(observers, evt)
        end
    end
end

"""
Apply a filter function such that only values for which the function returns
false will be passed onto [`Observer`](@ref)s
"""
function reject(fn)
    react() do observers, value
        if !fn(value)
            evt = ValueEvent(value)
            notify!(observers, evt)
        end
    end
end

"""
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
Emit only the integers in the range of m to n, inclusive
"""
function span(m, n)
    collect(range(m, length = (n - m + 1)))
end