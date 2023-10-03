using Distributed
addprocs(4)
# @everywhere using Pkg
# @everywhere Pkg.activate(".")
@everywhere begin
  # using NetCDF
  using DimensionalData
  using YAXArrays
  using Statistics
  using Zarr
end

Base.names(ds::Dataset) = string.(collect(keys(ds.cubes)))
Base.getindex(ds::Dataset, i) = ds[names(ds)[i]]
chunksize(cube) = Cubes.cubechunks(cube)


@everywhere function mymean(output, xin)
  # @show "doing a mean"
  output[:] .= quantile(xin, 0.5)
end

p = "data/temp-01.zarr/"
c = Cube(p)[Variable=At("var1")] # see OpenNetCDF to get the file


## 自行设计一个高性能的并行程序
indims = InDims("time")
outdims = OutDims()

# first time for precompile
# @time resultcube = mapCube(mymean, c[1:2, 1:2, :]; indims, outdims)

# second
@time resultcube = mapCube(mymean, c; indims, outdims)

# third
@time resultcube = mapCube(mymean, c; indims, outdims)

# > this one is low efficient, about 3 times slower
