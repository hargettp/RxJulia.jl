#! /usr/bin/env julia --project --color=yes

using Base.Filesystem

docsDir = abspath(dirname(@__FILE__))
baseDir = abspath(joinpath(docsDir, "../"))

if !in(LOAD_PATH,baseDir)
  push!(LOAD_PATH,baseDir)
end

using Documenter, RxJulia

makedocs(
  sitename="Documentation for RxJulia.jl"
  )