using Distributed
addprocs(4)

@everywhere begin
  using Distributed
  using SharedArrays
  using Statistics

  function _quantile(x::AbstractVector; probs=[0.1, 0.9])
    quantile(x, probs)
  end
end

## 并行版本的quantile
## 4核，可以快3倍左右，并行可以发挥作用；
function par_quantile(q; kw...)
  r = SharedArray{eltype(q)}(size(q)[1:2]..., 2)

  @sync @distributed for j = axes(q, 2)
    for i = axes(q, 1)
      x = @view(q[i, j, :])

      r[i, j, :] .= _quantile(x; kw...)
    end
  end
  sdata(r)
end;


## 01 precompile with a small data
dims = (10, 10, 365)
A = rand(dims...)
S = SharedArray(A)

@time r2 = par_quantile(S)
@time r1 = mapslices(_quantile, A, dims=3)

## 02 real action
println("Preparing Data ...")
dims = (1000, 1000, 365)
A = rand(dims...)
S = SharedArray(A)

println("Running ...")
@time r2 = par_quantile(S)
@time r1 = mapslices(_quantile, A, dims=3)

# Preparing Data ...
#  17.877270 seconds (6.96 M allocations: 3.084 GiB, 0.58% gc time)
#   5.809558 seconds (1.03 k allocations: 45.789 KiB)

# > 可以实现3倍的提速
