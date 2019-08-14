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

@test [1,3,5] == begin
    evts = @rx() do
        [1,2,3,4,5,6]
        select(isodd)
    end
    [evt for evt in evts]  
end

@test [2,4,6] == begin
    evts = @rx() do
        [1,2,3,4,5,6]
        reject(isodd)
    end
    [evt for evt in evts]  
end

@test [1,2,3] == begin
    evts = @rx() do
        [1,2,3,4,5,6,7,8,9]
        take(3)
    end
    [evt for evt in evts]  
end

@test [1,3,5] == begin
    evts = @rx() do
        [1,2,3,4,5,6,7,8,9]
        select(isodd)
        take(3)
    end
    [evt for evt in evts]  
end

@test [4,5,6] == begin
    evts = @rx() do
        [1,2,3,4,5,6]
        drop(3)
    end
    [evt for evt in evts]  
end

@test [1,2,3,4,5,6] == begin
    evts = @rx() do
        [1,2,3,4,5,6,7,8,9]
        cut(3)
    end
    [evt for evt in evts]  
end

@test [] == begin
    evts = @rx() do
        [1,2,3,4,5,6]
        cut(9)
    end
    [evt for evt in evts]  
end

@test [1,2,3] == begin
    evts = @rx() do
        [1,1,2,1,3,3,2,3]
        distinct()
    end
    [evt for evt in evts]  
end

@test [2,3,4,5] == begin
    evts = @rx() do
        span(2,5)
    end
    [evt for evt in evts]  
end
