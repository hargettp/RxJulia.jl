using Distributed

# We have to ask for other processes in our local cluster to start
addprocs(exeflags="--project")
# and we have to load the core module--or we deadlock
@everywhere using RxJulia

struct CustomTestSet <: Test.AbstractTestSet
    description::String
    delegate::Test.DefaultTestSet
end

function indent()
    last_test_depth = get(task_local_storage(), :last_test_depth, 0)
    depth = Test.get_testset_depth()
    task_local_storage(:last_test_depth, depth)
    nl = (depth != last_test_depth) ?  "\n" : ""
    repeat("$nl  ", depth) 
end

function CustomTestSet(description)
    printstyled(stdout, "$(indent())Testing $description", color=:light_blue)
    CustomTestSet(description, Test.DefaultTestSet(description))
end

function Test.record(ts::CustomTestSet, set::Test.AbstractTestSet)
    Test.record(ts.delegate, set)
end

function Test.record(ts::CustomTestSet, res::Test.Fail)
    printstyled(stdout, "!"; bold = true, color=Base.error_color())
    Test.record(ts.delegate, res)
end

function Test.record(ts::CustomTestSet, err::Test.Error)
    printstyled(stdout, "E"; bold = true, color=Base.error_color())
    Test.record(ts.delegate, err)
end

function Test.record(ts::CustomTestSet, res::Test.Pass)
    printstyled(stdout, "."; bold = true, color=:green)
    Test.record(ts.delegate, res)
end

function Test.finish(ts::CustomTestSet)
    printstyled(stdout, "DONE\n", color=:light_blue)
    Test.finish(ts.delegate)
end
