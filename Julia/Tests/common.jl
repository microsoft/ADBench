#Pkg.add("ForwardDiff")
#Pkg.update()
#Pkg.status()
using ForwardDiff

function logsumexp(x)
  mx = maximum(x)
  log(sum(exp(x - mx))) + mx
end

function ltri_unpack(D, LT)
  d=length(D)
  make_row(r::Int, L) = hcat(reshape([ L[i] for i=1:r-1 ],1,r-1), D[r], zeros(1,d-r))
  row_start(r::Int) = div((r-1)*(r-2),2)
  inds(r) = row_start(r)+(1:r-1)
  vcat([ make_row(r, LT[inds(r)]) for r=1:d ]...)
end

function get_Q(d,icf)
  ltri_unpack(exp(icf[1:d]),icf[d+1:end])
end

# Gradient helpers
function pack(alphas,means,icf)
  [alphas[:];means[:];icf[:]]
end

function unpack(d,k,packed)
  alphas = reshape(packed[1:k],1,k)
  off = k
  means = reshape(packed[(1:d*k)+off],d,k)
  icf_sz = div(d*(d + 1),2)
  off += d*k
  icf = reshape(packed[off+1:end],icf_sz,k)
  (alphas,means,icf)
end

# IO
function read_gmm_instance(fn,replicate_point)
  fid = open(fn)
  lines = readlines(fid)
  close(fid)
  line=split(lines[1]," ")
  d = int(line[1])
  k = int(line[2])
  n = int(line[3])
  icf_sz = div(d*(d + 1),2)
  off = 1

  alphas = zeros(Float64,1,k)
  for i in 1:k
    alphas[i] = float64(lines[i+off])
  end
  off += k

  means = zeros(Float64,d,k)
  for ik in 1:k
    line=split(lines[ik+off]," ")
    for id in 1:d
      means[id,ik] = float64(line[id])
    end
  end
  off += k

  icf = zeros(Float64,icf_sz,k)
  for ik in 1:k
    line=split(lines[ik+off]," ")
    for i in 1:icf_sz
      icf[i,ik] = float64(line[i])
    end
  end
  off += k

  if replicate_point
    x_ = zeros(Float64,d,1)
    line=split(lines[1+off]," ")
    for id in 1:d
      x_[id] = float64(line[id])
    end
    x = repmat(x_,1,n)
    off += 1
  else
    x = zeros(Float64,d,n)
    for ix in 1:n
      line=split(lines[ix+off]," ")
      for id in 1:d
        x[id,ix] = float64(line[id])
      end
    end
    off += n
  end
  (alphas,means,icf,x)
end
