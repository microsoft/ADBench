include("common_io.jl")
type Wishart
  gamma::Float64
  m::Int
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

function log_gamma_distrib(a, p)
  out = 0.25 * p * (p - 1) * log(pi)
	for j in 1:p
    out += lgamma(a + 0.5*(1 - j))
  end
	out
end

function log_wishart_prior(wishart::Wishart, sum_qs, Qs, icf)
  p = size(Qs[1],1)
  n = p + wishart.m + 1
  C = n*p*(log(wishart.gamma) - 0.5*log(2)) - log_gamma_distrib(0.5*n, p)

  frobenius = 0.
  for Q in Qs
    frobenius += sumabs2(diag(Q))
  end
  frobenius += sumabs2(icf[d+1:end,:])
	0.5*wishart.gamma^2 * frobenius - wishart.m*sum(sum_qs) - k*C
end

# IO
function read_gmm_instance(fn,replicate_point)
  fid = open(fn)
  lines = readlines(fid)
  close(fid)
  line=split(lines[1]," ")
  d = parse(Int,line[1])
  k = parse(Int,line[2])
  n = parse(Int,line[3])
  icf_sz = div(d*(d + 1),2)
  off = 1

  alphas = zeros(Float64,1,k)
  for i in 1:k
    alphas[i] = parse(Float64,lines[i+off])
  end
  off += k

  means = zeros(Float64,d,k)
  for ik in 1:k
    line=split(lines[ik+off]," ")
    for id in 1:d
      means[id,ik] = parse(Float64,line[id])
    end
  end
  off += k

  icf = zeros(Float64,icf_sz,k)
  for ik in 1:k
    line=split(lines[ik+off]," ")
    for i in 1:icf_sz
      icf[i,ik] = parse(Float64,line[i])
    end
  end
  off += k

  if replicate_point
    x_ = zeros(Float64,d,1)
    line=split(lines[1+off]," ")
    for id in 1:d
      x_[id] = parse(Float64,line[id])
    end
    x = repmat(x_,1,n)
    off += 1
  else
    x = zeros(Float64,d,n)
    for ix in 1:n
      line=split(lines[ix+off]," ")
      for id in 1:d
        x[id,ix] = parse(Float64,line[id])
      end
    end
    off += n
  end
  line = split(lines[1+off]," ")
  wishart = Wishart(parse(Float64,line[1]),parse(Int,line[2]))
  (alphas,means,icf,x,wishart)
end
