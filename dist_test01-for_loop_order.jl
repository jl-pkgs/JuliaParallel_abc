using Distributed
addprocs(4)

@everywhere begin
  using Distributed
  using SharedArrays
  using Statistics
end

function advection_serial!(q, u)
  # @show (irange, jrange, trange)  # display so we can see what's happening
  trange = 1:size(q, 3)-1
  jrange = axes(q, 2)
  irange = axes(q, 1)

  for t in trange, j in jrange, i in irange
    q[i, j, t+1] = q[i, j, t] + u[i, j, t]
  end
  q
end

function advection_parallel!(q, u)
  @sync @distributed for j = axes(q, 2)
    for i = axes(q, 1)
      for t = 1:size(q, 3)-1
        q[i, j, t+1] = q[i, j, t] + u[i, j, t]
      end
    end
  end
  q
end;

## 更复杂的一种实现方法
@everywhere function advection_shared_chunk!(q, u)
  idx = indexpids(q)
  nchunks = length(procs(q))
  nrow, ncol = size(q)[1:2]
  lst = r_chunk(ncol, nchunks)
  jrange = lst[idx]
  @show jrange

  for j = jrange
    for i = axes(q, 1)
      for t = 1:size(q, 3)-1
        q[i, j, t+1] = q[i, j, t] + u[i, j, t]
      end
    end
  end
end

function advection_shared!(q, u)
  @sync begin
    for p in procs(q)
      @async remotecall_wait(advection_shared_chunk!, p, q, u)
    end
  end
  q
end




q = SharedArray{Float64,3}((500, 500, 500));
u = SharedArray{Float64,3}((500, 500, 500));

## 提速并不明显
@time advection_serial!(q, u);
@time advection_parallel!(q, u);
@time advection_shared!(q, u);
