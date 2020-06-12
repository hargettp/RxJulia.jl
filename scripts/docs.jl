#! /usr/bin/env julia --color=yes

using Base.Filesystem

scriptsDir = abspath(dirname(@__FILE__))
baseDir = abspath(joinpath(scriptsDir, "../"))
srcDir = abspath(joinpath(baseDir, "src/"))
docsDir = abspath(joinpath(scriptsDir, "../docs/"))
docSrcDir = abspath(joinpath(docsDir, "src/"))

if !in(baseDir, LOAD_PATH)
  push!(LOAD_PATH, baseDir)
end

using FileWatching
using Logging

while true
  cd(docsDir) do
    run(`julia --color=yes make.jl`)
  end
  # println("\n\nWaiting for changes in $srcDir...")
  @info "Waiting for changes in $srcDir..."
  watch_folder(srcDir)
end
