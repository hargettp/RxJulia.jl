using Distributed

"""
Intended to be used with macros, `macroArguments` extracts both positional
and keyword arguments. The return value is a tuple containing 3 slots:
  * a function or `nothing` if no function argument provided
  * an array of positional arguments
  * a dictionary of keyword arguments. The keys of the dictionary are `Symbol`s
"""
function macroArguments(arguments)::Tuple{Union{Expr,Nothing},Vector{Any},Dict{Symbol,Any}}
  functional = nothing
  positional = []
  keywords = Dict{}()
  for i in eachindex(arguments)
    argument = arguments[i]
    if i == 1 && argument isa Expr && argument.head === :(->)
      functional = argument
    elseif argument isa Expr && argument.head === :(kw)
      kw, arg = argument.args
      keywords[kw] = arg
    else
      push!(positional, argument)
    end
  end
  (functional, positional, keywords)
end

macro anywhere(expr)
  :(@async fetch(@spawnat :any $(expr)) )
end