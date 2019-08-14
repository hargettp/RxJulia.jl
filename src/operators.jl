export select, take, drop

using DataStructures

# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 
#
# Various types of operators for creating new `Observable`s
#
# / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / 

"""
Apply a filter function such that only values for which the function returns
true will be passed onto `Observer`s
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
Drop the last n events observed, emitting all others that precede them. If less than n 
events observed, emit nothing.
"""
function drop(n)
    let backlog = Queue{Int64}()
        counter = n
        react() do observers, value
            enqueue!(backlog, value)
            if counter > 0
                counter -= 1
            else
                value = dequeue!(backlog)
                notify!(observers, ValueEvent(value))
            end
        end
    end
end