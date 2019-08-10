using Test
using RxJulia

@test 1 == 1

@test [1,2,3] == begin
    evts = @rx() do
        [1,2,3]
    end
    [evt for evt in evts]  
end
