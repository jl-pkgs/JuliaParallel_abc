# using Distributed
# addprocs(4)
# @everywhere using Pkg
# @everywhere Pkg.activate(".")
# @everywhere begin
# using NetCDF
using DimensionalData
using YAXArrays
using Statistics
using Zarr
using Ipaper
using ProgressMeter
# end

## 手动并行的一种方案

# @everywhere 
mymean(xin::AbstractVector) = quantile(xin, 0.5)

p = "data/temp-01.zarr/"
c = Cube(p)[Variable=At("var1")] # see OpenNetCDF to get the file

function cube_mean(c)
  _, nrow, ncol = size(c)
  r = zeros(nrow, ncol)

  grids = c.chunks
  # @sync begin
  p = Progress(length(grids))
  # Threads.@threads
  @par for k = eachindex(grids)
    # println("k = $k")
    next!(p)
    g = grids[k]
    _, ix, iy = g
    data = c.data[g...]
    # display(data)
    r[ix, iy] .= mapslices(mymean, data, dims=1)[1, :, :] # 
  end
  # end
  r
end

# indims = InDims("time")
# outdims = OutDims()

println("Running ...")
# @time resultcube = mapCube(mymean, c[:, 1:2, 1:2]; indims, outdims)
# @time resultcube = mapCube(mymean, c; indims, outdims)
# @time resultcube = cube_mean(c[:, 1:2, 1:2]);
@time resultcube = cube_mean(c);
@time resultcube = cube_mean(c);
