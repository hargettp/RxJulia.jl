var documenterSearchIndex = {"docs":
[{"location":"#RxJulia-Guide-1","page":"RxJulia Guide","title":"RxJulia Guide","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"This package is an implementation of the ReactiveX reactive programming model in Julia.","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Just like other libraries in the ReactiveX ecosystem, the basic Observable and Subject types exist (the latter is called Reactor here),  together with many operators for constructing new observables from existing ones.","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"RxJulia takes advantage of Julia's macro and type systems to create a domain-specific language (DSL) useful in reactive programming: see Pipelines for more details.","category":"page"},{"location":"#Contents-1","page":"RxJulia Guide","title":"Contents","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Depth = 3","category":"page"},{"location":"#Pipelines-1","page":"RxJulia Guide","title":"Pipelines","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"One area that is unique to RxJulia is the use of macros to create pipelines or chains of Reactor  instances in code. Specifically the @rx macro makes this possible. ","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"events = @rx do\n  observableFactory1\n  reactorFactory1\n  reactorFactory2\n  # more....\nend\n\nfor event in events\n  # do something with the event.\nend","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Note that intermediate stages in a pipeline are Reactors, capable of both being an Observer and an Observable. Both the beginning and the end of the pipeline should be an Observable (of course, another Reactor is fine too). A Reactor is the analogue of a Subject in the ReactiveX model.","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"When using @rx, a special observable, a Collector, is added to the end of the chain, resulting in an object suitable for iteration. Iteration ends when a CompletedEvent or an ErrorEvent are encountered. Thus, it is possible to iterate over the events generated from the created pipeline.","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"using RxJulia # hide\nevt = @rx(() -> 1)","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Each statment inside the @rx block is actually an expression that should be a factory for creating an Observable or Reactor, and each line subscribes to the events generated by the line above it, with subscribe!. ","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Fortunately, nearly any value will work as an Observable: scalar values such as strings, numbers, booleans, symbols, etc., all result in an Observable that produces only a single value before completion. ","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"using RxJulia # hide\nevts = @rx() do\n  1\nend\nfor evt in evts\n  println(\"Event: $evt\")\nend","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Values that are iterable will result in a stream of values passed to the downstream observers, completing when iteration ends.","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"using RxJulia # hide\nevts = @rx() do\n  [1 2 3]\nend\nfor evt in evts\n  println(\"Event: $evt\")\nend","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Chaining occurs naturally within the pipeline (see detect for its meaning in this context):","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"using RxJulia # hide\nevts = @rx() do\n  [1, 2, 3, 4, 5, 6]\n  detect(isodd)\nend\nprintln([evt for evt in evts])","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Each pipeline created with @rx is itself an Observable.","category":"page"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"using RxJulia # hide\nevts1 = @rx() do\n  [1 2 3]\nend\n\nevts2 = @rx() do\n  evts1\nend\n\nfor evt in evts2\n  println(\"Event: $evt\")\nend","category":"page"},{"location":"#Kernel-1","page":"RxJulia Guide","title":"Kernel","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"The kernel is the fundamental implementation of the reactive pattern in Julia, independent of any operators that leverage the package's capabilities.","category":"page"},{"location":"#Functions-1","page":"RxJulia Guide","title":"Functions","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Modules = [RxJulia]\nPages = [\"kernel.jl\"]\nOrder = [:function]","category":"page"},{"location":"#RxJulia.collector","page":"RxJulia Guide","title":"RxJulia.collector","text":"collector(buffer = 0)\n\nReturn a Collector to accumulate observed Events. If set to a value greater than 0, then events will be buffered with a Channel with the specified buffer size, throttling incoming events until the channel has empty slots.\n\n\n\n\n\n","category":"function"},{"location":"#RxJulia.dispatch-Tuple{Function}","page":"RxJulia Guide","title":"RxJulia.dispatch","text":"dispatch(fn::Function)::Reactor = Reactor(fn)\n\nReturn a Reactor around the provided function which takes Observers  and an Event, taking action as appropriate, and producing an Observable that can also be an Observer of other Observables.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.notify!-Tuple{Any,Any}","page":"RxJulia Guide","title":"RxJulia.notify!","text":"notify!(observers, event)\n\nNotify Observer by invoking the block on each\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.onEvent-Tuple{Any,Any}","page":"RxJulia Guide","title":"RxJulia.onEvent","text":"onEvent(observer, event)\n\nDeliver an Event to the Observer\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.react-Tuple{Function}","page":"RxJulia Guide","title":"RxJulia.react","text":"react(fn::Function)::Reactor\n\nReturn a Reactor around the provided function which takes Observers  and a value, taking action as appropriate, and producing an Observable that can also be an Observer of other Observables. CompletedEvents and ErrorEvents are passed on to Observers, while ValueEvents are passed to the supplied function. The supplied function takes Observers and a value as arguments.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.subscribe!-Tuple{Any,Any}","page":"RxJulia Guide","title":"RxJulia.subscribe!","text":"Treat any value as an Observable, and subscribe the Observer to it; the value will be emitted once with a ValueEvent, then a CompletedEvent will be emitted. If the value is iterable (e.g., applicable(iterate, value) returns true), then emit over each value returned by the iterable and pass on to the Observer, concluding with a CompletedEvent. Note that strings are treated as an atomic value and not  an iterable.\n\n# works for booleans\njulia> evts = @rx(() -> true)\nCollector(Channel{Any}(sz_max:32,sz_curr:2))\n\njulia> collect(evts)\n1-element Array{Any,1}:\n true\n\n# works for booleans\njulia> evts = @rx( ()-> 1 )\nCollector(Channel{Any}(sz_max:32,sz_curr:2))\n\njulia> collect(evts)\n1-element Array{Any,1}:\n 1\n\n# works for strings\njulia> evts = @rx( ()-> \"foo\" )\nCollector(Channel{Any}(sz_max:32,sz_curr:2))\n\njulia> collect(evts)\n1-element Array{Any,1}:\n \"foo\"\n\n# works for iterables\njulia> evts = @rx( ()-> [1 2 3] )\nCollector(Channel{Any}(sz_max:32,sz_curr:4))\n\njulia> collect(evts)\n3-element Array{Any,1}:\n 1\n 2\n 3\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.subscribe!-Tuple{Array{Observer,1},Any}","page":"RxJulia Guide","title":"RxJulia.subscribe!","text":"subscribe!(observers::Observers, observer)\n\nAdd an Observer to an existing set of Observers, return the Observer\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.subscribe!-Tuple{Observable,Any}","page":"RxJulia Guide","title":"RxJulia.subscribe!","text":"subscribe!(observable::Observable, observer)\n\nSubscribe an Observer to the given Observable, return the Observer\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.chain!-Tuple{Any,Any}","page":"RxJulia Guide","title":"RxJulia.chain!","text":"chain!(observable, observer)\n\nSubscribe the Observer to the Observable using subscribe!,  and return the Observable.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.complete!-Tuple{Any}","page":"RxJulia Guide","title":"RxJulia.complete!","text":"complete!(observers)\n\nEmit a CompletedEvent to Observers\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.error!-Tuple{Any,Any}","page":"RxJulia Guide","title":"RxJulia.error!","text":"error!(observers, err)\n\nEmit an ErrorEvent to Observers\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.subscribe_iterable!-Tuple{Any,Any}","page":"RxJulia Guide","title":"RxJulia.subscribe_iterable!","text":"subscribe_iterable!(iterable, observer)\n\nTreat an iteraable as an Observable, emitting each of its elements in turn  in a ValueEvent, and concluding with a CompletedEvent.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.subscribe_value!-Tuple{Any,Any}","page":"RxJulia Guide","title":"RxJulia.subscribe_value!","text":"subscribe_value!(value, observer)\n\nTreat a value as an Observable, emitting the value followed by a CompletedEvent\n\n\n\n\n\n","category":"method"},{"location":"#Macros-1","page":"RxJulia Guide","title":"Macros","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Modules = [RxJulia]\nPages = [\"kernel.jl\"]\nOrder = [:macro]","category":"page"},{"location":"#RxJulia.@rx","page":"RxJulia Guide","title":"RxJulia.@rx","text":"rx(blk,buffer=0)\n\nGiven a do-block where each statement is an Observable,  subscribe! each in sequence to the one proceeding. Return an object that one can use to iterate over the events from the last Observable in the block. The value of buffer is passed to collector in order to create a potentially buffered Channel for the Collector at the end of the pipeline.\n\nExample:\n\nresults = @rx() do\ncount\nfilter(:even)\nend\nprintlin([result for result in results])\n\n\n\n\n\n","category":"macro"},{"location":"#Types-1","page":"RxJulia Guide","title":"Types","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Modules = [RxJulia]\nPages = [\"kernel.jl\"]\nOrder = [:type]","category":"page"},{"location":"#RxJulia.Collector","page":"RxJulia Guide","title":"RxJulia.Collector","text":"An Observer that accumulates events on a Channel, which then may be retrieved for iteration\n\n\n\n\n\n","category":"type"},{"location":"#RxJulia.CompletedEvent","page":"RxJulia Guide","title":"RxJulia.CompletedEvent","text":"An Event signifying no more events are available from the originating Observable.\n\n\n\n\n\n","category":"type"},{"location":"#RxJulia.ErrorEvent","page":"RxJulia Guide","title":"RxJulia.ErrorEvent","text":"An Event signifying the originating Observable encountered an error; no more events will be delivered after events of tyie.\n\n\n\n\n\n","category":"type"},{"location":"#RxJulia.Observable","page":"RxJulia Guide","title":"RxJulia.Observable","text":"An Observable is a source of Events, with Observers  subscribe!ing to the Observable in order to receive those events. \n\nSee Observable in ReactiveX documentation\n\n\n\n\n\n","category":"type"},{"location":"#RxJulia.Observer","page":"RxJulia Guide","title":"RxJulia.Observer","text":"An Observer is a receiver of Events via onEvent\n\n\n\n\n\n","category":"type"},{"location":"#RxJulia.Reactor","page":"RxJulia Guide","title":"RxJulia.Reactor","text":"Reactor() = Reactor(notify!)\nReactor(fn) = Reactor(fn, [])\n\nA Reactor is an Observer that is also useful for building Observers that are Observable as well.\n\nA Reactor is the analogue of a Subject in the ReactiveX model.\n\n\n\n\n\n","category":"type"},{"location":"#RxJulia.ValueEvent","page":"RxJulia Guide","title":"RxJulia.ValueEvent","text":"An Event containing a value to deliver to an Observable.\n\n\n\n\n\n","category":"type"},{"location":"#RxJulia.Observers","page":"RxJulia Guide","title":"RxJulia.Observers","text":"Observers is a collection of subscribed Observers\n\n\n\n\n\n","category":"type"},{"location":"#Constants-1","page":"RxJulia Guide","title":"Constants","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Modules = [RxJulia]\nPages = [\"kernel.jl\"]\nOrder = [:constant]","category":"page"},{"location":"#RxJulia.Event","page":"RxJulia Guide","title":"RxJulia.Event","text":"An Event is any of the following:\n\nA value, encapsulated as ValueEvent\nA completion event, encapsulated as CompletedEvent\nAn error, encapsulated as ErrorEvent\n\n\n\n\n\n","category":"constant"},{"location":"#Operators-1","page":"RxJulia Guide","title":"Operators","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Operators are useful functions for producing Reactors that receive events and decide whether to transform them or skip emitting values to downstream observers.","category":"page"},{"location":"#Functions-2","page":"RxJulia Guide","title":"Functions","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"Modules = [RxJulia]\nPages = [\"operators.jl\"]\nOrder = [:function]","category":"page"},{"location":"#RxJulia.average-Tuple{}","page":"RxJulia Guide","title":"RxJulia.average","text":"average()\n\nCompute an average of all values observed.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.cut-Tuple{Any}","page":"RxJulia Guide","title":"RxJulia.cut","text":"cut(n)\n\nDrop the last n events observed, emitting all others that precede them. If less than n  events observed, emit nothing. See drop\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.detect-Tuple{Function}","page":"RxJulia Guide","title":"RxJulia.detect","text":"detect(fn::Function)\n\nApply a filter function such that only values for which the function returns true will be passed onto Observers. See ignore.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.distinct-Tuple{}","page":"RxJulia Guide","title":"RxJulia.distinct","text":"distinct()\n\nOnly emit unique values observed\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.drop-Tuple{Any}","page":"RxJulia Guide","title":"RxJulia.drop","text":"drop(n)\n\nDrop the first n events observed, emitting all others that precede them. If less than n  events observed, emit nothing. See cut.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.fmap-Tuple{Function}","page":"RxJulia Guide","title":"RxJulia.fmap","text":"fmap(fn::Function)\n\nApply function to all observed values, and emit the result. Functional equivalent of map.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.ignore-Tuple{Function}","page":"RxJulia Guide","title":"RxJulia.ignore","text":"ignore(fn::Function)::Reactor\n\nApply a filter function such that only values for which the function returns false will be passed onto Observers. See detect.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.keep-Tuple{Any}","page":"RxJulia Guide","title":"RxJulia.keep","text":"keep(n)\n\nKeep only the last n values, discarding the rest. If less than n values observed, emit only values observed. See take.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.max-Tuple{}","page":"RxJulia Guide","title":"RxJulia.max","text":"max()\n\nCompute the max of all values observed.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.merge-Tuple","page":"RxJulia Guide","title":"RxJulia.merge","text":"merge(observables...)\n\nProduce an Observable that emits from the supplied Observables, until either all have emitted a CompletedEvent or one of them emits  an ErrorEvent\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.min-Tuple{}","page":"RxJulia Guide","title":"RxJulia.min","text":"min()\n\nCompute min of all values observed.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.span-Tuple{Any,Any}","page":"RxJulia Guide","title":"RxJulia.span","text":"span(m, n)\n\nEmit only the integers in the range of m to n, inclusive. Effectively an explicit alternative  to using range literal m:n.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.sum-Tuple{}","page":"RxJulia Guide","title":"RxJulia.sum","text":"sum()\n\nCompute a sum of all values observed.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.take-Tuple{Any}","page":"RxJulia Guide","title":"RxJulia.take","text":"take(n)\n\nTake only the first n values, discarding the rest. If less than n values observed, emit only values observed. See keep.\n\n\n\n\n\n","category":"method"},{"location":"#RxJulia.zip-Tuple","page":"RxJulia Guide","title":"RxJulia.zip","text":"zip(observables...)\n\nGiven one or more Observables, read one value at a time from each and collect into a Tuple, stopping when either there is an ErrorEvent or any CompletedEvent\n\n\n\n\n\n","category":"method"},{"location":"#Index-1","page":"RxJulia Guide","title":"Index","text":"","category":"section"},{"location":"#","page":"RxJulia Guide","title":"RxJulia Guide","text":"","category":"page"}]
}
