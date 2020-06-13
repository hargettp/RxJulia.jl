#! /usr/bin/env julia --project --color=yes

if !in(LOAD_PATH,"..")
  push!(LOAD_PATH,"..")
end

using Documenter, RxJulia

makedocs(
  sitename="Documentation for RxJulia.jl"
  )