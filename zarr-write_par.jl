## 编写一个保存数据的函数
using Zarr: AbstractStore, store_read_strategy, SequentialRead, ConcurrentRead, NoCompressor
using YAXArrays, Statistics, Zarr, NetCDF
using DimensionalData
using Dates

Base.names(ds::Dataset) = string.(collect(keys(ds.cubes)))
Base.getindex(ds::Dataset, i) = ds[names(ds)[i]]
chunksize(cube) = Cubes.cubechunks(cube)

# add the `overwrite` option to zarr
## DirectoryStore
function zarr_group(s::String; overwrite=false, mode="w", kw...)
  if overwrite && isdir(s)
    rm(s, recursive=true, force=true)
  end
  isdir(s) ? zopen(s, mode) : zgroup(s; kw...)
end

# Zarr.store_read_strategy(::DirectoryStore) = ConcurrentRead(Zarr.concurrent_io_tasks[])
# Zarr.concurrent_io_tasks[] = 50


## 1. 生成数据
axlist = (
  Dim{:time}(Date("2022-01-01"):Day(1):Date("2022-12-31")),
  Dim{:lon}(range(1, 10, length=1000)),
  Dim{:lat}(range(1, 5, length=1500))
)

data = rand(axlist...)
ds_raw = YAXArray(axlist, data)

#Save the cube to zarr for parallel processing
ds = setchunks(ds_raw, (time=365, lon=100, lat=150))


## 2. 保存数据

# p = "data/temp-01.zarr"
# @time savecube(ds, p, backend=:zarr)
p = "data/temp-02.zarr"
isdir(p) && (rm(p, recursive=true, force=true))

g = zarr_group(p)

t = nonmissingtype(eltype(data))
dims = size(data)[1:3]

compressor = NoCompressor()
# how to automatically get the chunk size? 
chunks = (365, 100, 150)

@show t, dims, chunks
z = zcreate(t, g, "var1", dims...; chunks, compressor)

@time z[:] = ds.data[:, :, :];

## 并行模式下
# 11.767829 seconds (2.70 M allocations: 8.369 GiB, 1.67% gc time, 13.49% compilation time)

# 并行与否，速度上没有差别
