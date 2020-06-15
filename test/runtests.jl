using Test
using RxJulia

include("./support.jl")

@testset CustomTestSet "Basics" begin

  @test 1 == 1

  @test [1, 2, 3] == begin
    evts = @rx() do
      [1, 2, 3]
    end
    [evt for evt in evts]
  end

  function plus3(observers, x)
    evt = ValueEvent(x + 3)
    notify!(observers, evt)
  end

  @test [4, 5, 6] == begin
    evts = @rx() do
      [1, 2, 3]
      react(plus3)
    end
    [evt for evt in evts]
  end

  @test [4, 5, 6] == begin
    evts = @rx() do
      [1, 2, 3]
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

  @test [1, 3, 5] == begin
    evts = @rx() do
      [1, 2, 3, 4, 5, 6]
      detect(isodd)
    end
    [evt for evt in evts]
  end

  @test [2, 4, 6] == begin
    evts = @rx() do
      [1, 2, 3, 4, 5, 6]
      ignore(isodd)
    end
    [evt for evt in evts]
  end

  @test [2, 3, 4] == begin
    evts = @rx() do
      [1, 2, 3]
      fmap() do value
        value + 1
      end
    end
    [evt for evt in evts]
  end

  @test [1, 2, 3] == begin
    evts = @rx() do
      [1, 2, 3, 4, 5, 6, 7, 8, 9]
      take(3)
    end
    [evt for evt in evts]
  end

  @test [7, 8, 9] == begin
    evts = @rx() do
      [1, 2, 3, 4, 5, 6, 7, 8, 9]
      keep(3)
    end
    [evt for evt in evts]
  end

  @test [1, 3, 5] == begin
    evts = @rx() do
      [1, 2, 3, 4, 5, 6, 7, 8, 9]
      detect(isodd)
      take(3)
    end
    [evt for evt in evts]
  end

  @test [4, 5, 6] == begin
    evts = @rx() do
      [1, 2, 3, 4, 5, 6]
      drop(3)
    end
    [evt for evt in evts]
  end

  @test [1, 2, 3, 4, 5, 6] == begin
    evts = @rx() do
      [1, 2, 3, 4, 5, 6, 7, 8, 9]
      cut(3)
    end
    [evt for evt in evts]
  end

  @test [] == begin
    evts = @rx() do
      [1, 2, 3, 4, 5, 6]
      cut(9)
    end
    [evt for evt in evts]
  end

  @test [1, 2, 3] == begin
    evts = @rx() do
      [1, 1, 2, 1, 3, 3, 2, 3]
      distinct()
    end
    [evt for evt in evts]
  end

  @test [2, 3, 4, 5] == begin
    evts = @rx() do
      span(2, 5)
    end
    [evt for evt in evts]
  end

  @test Set([1 2 3 4 5 6 7]) == begin
    evts3 = @rx() do
      let evts1 = @rx(() -> [1 2 3])
        evts2 = @rx(() -> [4 5 6 7])
        RxJulia.merge(evts1, evts2)
      end
    end
    Set([evt for evt in evts3])
  end

  @test [(1, 4), (2, 5), (3, 6)] == begin
    evts3 = @rx() do
      let evts1 = @rx(() -> [1 2 3])
        evts2 = @rx(() -> [4 5 6])
        RxJulia.zip(evts1, evts2)
      end
    end
    [evt for evt in evts3]
  end

  @test [6] == begin
    evts = @rx() do
      [1 2 3]
      RxJulia.sum()
    end
    [evt for evt in evts]
  end

  @test [2] == begin
    evts = @rx() do
      [1 2 3]
      RxJulia.average()
    end
    [evt for evt in evts]
  end

  @test [3] == begin
    evts = @rx() do
      [1 2 3]
      RxJulia.max()
    end
    [evt for evt in evts]
  end

  @test [1] == begin
    evts = @rx() do
      [1 2 3]
      RxJulia.min()
    end
    [evt for evt in evts]
  end

end
