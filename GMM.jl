function logsumexp(x::Vector)
    log(sum(exp(x)))
end

# Make matrix from diagonal and strict lower triangle, 
# e.g. D = [d11 d22 d33 d44]
#      LT = [L21 L31 L32 L41 L42 L43]
# Outputting
#  [d11   0   0   0]
#  [L21 d12   0   0] # row r: Ls starting at sum_i=1^r 
#  [L31 L32 d33   0]
#  [L41 L42 L43 d44]
function make_L(D::Array, LT::Array)
    d=length(D)
    make_row(r, L) = hcat(reshape([ L[i] for i=1:r-1 ],1,r-1), D[r], zeros(1,d-r))
    row_start(r) = (r-1)*(r-2)/2
    vcat([ make_row(r, LT[row_start(r)+(1:r-1)]) for r=1:d ]...)
end

make_L([11 22 33 44], [21 31 32 41 42 43])

#@test [11 0 0 0; 21 22 0 0 ; 31 32 33 0 ; 41 42 43 44] == make_L([11 22 33 44], [21 31 32 41 42 43])

    
#function ll(g::GMM, x::Array)
    
#    [x-g.mus[i] for i in 1:g.n]
#end

#tril(rand(4,4))
