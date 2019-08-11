using Test
using RxJulia

@test 1 == 1

@test [1,2,3] == begin
    evts = @rx() do
        [1,2,3]
    end
    [evt for evt in evts]  
end

function plus3(observers, x)
    evt = ValueEvent(x + 3)
    for observer in observers
        onEvent(observer, evt)
    end
end

@test [4,5,6] == begin
    evts = @rx() do
        [1,2,3]
        Reactor(plus3)
    end
    [evt for evt in evts]  
end
