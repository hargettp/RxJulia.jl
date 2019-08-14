export select

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
