using YAXArrays, Statistics, Zarr, NetCDF
using DimensionalData
using Dates


p = "data/temp-01.zarr/"
c = Cube(p)[Variable=At("var1")] # see OpenNetCDF to get the file

function mymean(output, xin)
  # @show "doing a mean"
  output[:] .= quantile(xin, 0.5)
end

indims = InDims("time")
outdims = OutDims()

# @time resultcube = mapCube(mymean, c[:, 1:10, 1:10]; indims, outdims)
@time resultcube = mapCube(mymean, c; indims, outdims)
@time resultcube = mapCube(mymean, c; indims, outdims)

# 需要27s
# 27.273811 seconds (3.01 M allocations: 12.840 GiB, 10.77% gc time)
