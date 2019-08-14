export select, take

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