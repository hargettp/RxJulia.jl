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
    notify!(observers, evt)
end

@test [4,5,6] == begin
    evts = @rx() do
        [1,2,3]
        Reactor(plus3)
    end
    [evt for evt in evts]  
end

@test [4,5,6] == begin
    evts = @rx() do
        [1,2,3]
        react(plus3)
    end
    [evt for evt in evts]  
end

@test [1] == begin
    evts = @rx() do
        1
    end
    [evt for evt in evts]  
end
