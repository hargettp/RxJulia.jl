#! /usr/bin/env julia --color=yes

using Base.Filesystem
using Pkg

scriptsDir = abspath(dirname(@__FILE__))
baseDir = abspath(joinpath(scriptsDir, "../"))
srcDir = abspath(joinpath(baseDir, "src/"))
docsDir = abspath(joinpath(scriptsDir, "../docs/"))
docSrcDir = abspath(joinpath(docsDir, "src/"))
buildDir = abspath(joinpath(scriptsDir, "../docs/build/"))

Pkg.activate(docsDir)

using FileWatching
using Logging
using HTTP
using Sockets

function watchDir(changes,dir)
  @async begin
    while true
      @info ">>>  Waiting for changes in $dir..."
      change = watch_folder(dir)
      put!(changes, change)
    end
  end
end

function contentType(filePath)
  if filePath[end-4:end] == ".html"
    return "text/html"
  elseif filePath[end-2:end] == ".js"
    return "text/javascript"
  elseif filePath[end-3:end] == ".css"
    return "text/css"
  elseif (filePath[end-3:end] == ".jpg" || filePath[end-4:end] == ".jpeg")
    return "image/jpeg"
  elseif filePath[end-3:end] == ".png"
    return "image/png"
  elseif filePath[end-4:end] == ".json"
    return "application/json"
  elseif filePath[end-3:end] == ".ico"
    return "image/vnd.microsoft.icon"
  else
    return "application/octet-stream"
  end
end

function serveDir(dir)
  @async begin
    HTTP.serve(Sockets.localhost,8080) do req::HTTP.Request
        path = req.target
        @info "Serving $path"
        if path[begin] == '/'
          path = path[begin+1:end]
        end
        filePath = abspath(joinpath(buildDir,path))
        if filePath[end] == '/'
          filePath *= "index.html"
        end
        if ispath(filePath)
          response = HTTP.Response(200, read(filePath))
          HTTP.setheader(response,"Content-Type" => contentType(filePath))
          return response
        else
          return HTTP.Response(404,"Not found")
        end
    end  
  end
end

@sync begin
  changes = Channel()
  watchDir(changes, docSrcDir)
  watchDir(changes, srcDir)
  serveDir(buildDir)
  @async begin
    @info ">>>  Triggering initial generation of documentation"
    put!(changes, :first)
  end
  for change in changes
    cd(docsDir) do
      try
        run(`julia --color=yes make.jl`)
        @info ">>>  Generation complete"
      catch ex
        @error "!!!  Error generating docs: $ex"
      end
    end
  end
end
