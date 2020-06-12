# RxJulia Guide

This package is an implementation of the [ReactiveX](http://reactivex.io) reactive programming model in Julia.

Just like other libraries in the ReactiveX ecosystem, the basic [`Observable`](@ref) type exists, 
together with many operators for constructing new observables from existing ones.

One area that is unique to RxJulia is the use of macros to create pipelines or chains of [`Observable`](@ref) 
instances in code. Specifically the [`@rx`](@ref) macro makes this possible.

```@contents
Depth = 3
```

## Kernel

### Functions

```@autodocs
Modules = [RxJulia]
Pages = ["kernel.jl"]
Order = [:function]
```

### Macros

```@autodocs
Modules = [RxJulia]
Pages = ["kernel.jl"]
Order = [:macro]
```

### Types

```@autodocs
Modules = [RxJulia]
Pages = ["kernel.jl"]
Order = [:type]
```

### Constants

```@autodocs
Modules = [RxJulia]
Pages = ["kernel.jl"]
Order = [:constant]
```

## Operators

### Functions

```@autodocs
Modules = [RxJulia]
Pages = ["operators.jl"]
Order = [:function]
```

### Macros

```@autodocs
Modules = [RxJulia]
Pages = ["operators.jl"]
Order = [:macro]
```

### Types

```@autodocs
Modules = [RxJulia]
Pages = ["operators.jl"]
Order = [:type]
```

### Constants

```@autodocs
Modules = [RxJulia]
Pages = ["operators.jl"]
Order = [:constant]