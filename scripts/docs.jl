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

function watchDir(changes,dir)
  @async begin
    while true
      @info ">>>  Waiting for changes in $dir..."
      change = watch_folder(dir)
      put!(changes, change)
    end
  end
end

@sync begin
  changes = Channel()
  watchDir(changes, docSrcDir)
  watchDir(changes, srcDir)
  @async begin
    @info ">>>  Triggering initial generation of documentation"
    put!(changes, :first)
  end
  for change in changes
    cd(docsDir) do
      run(`julia --color=yes make.jl`)
    end
    @info ">>>  Generation complete"
  end
end
