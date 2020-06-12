#! /usr/bin/env julia --color=yes

if !in(LOAD_PATH,"..")
  push!(LOAD_PATH,"..")
end

using Documenter, RxJulia

makedocs(
  sitename="Documentation for RxJulia.jl"
  )