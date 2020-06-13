include("./make.jl")

deploydocs(
    repo = "github.com/$(ENV["GITHUB_REPOSITORY"]).git",
)

