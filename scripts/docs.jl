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

@sync begin
  changes = Channel()
  @async begin
    while true
      @info ">>>  Waiting for changes in $docSrcDir..."
      change = watch_folder(docSrcDir)
      put!(changes, change)
    end
  end
  @async begin
    while true
      @info ">>>  Waiting for changes in $srcDir..."
      change = watch_folder(srcDir)
      put!(changes, change)
    end
  end
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
