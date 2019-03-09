function write_J(fn,J)
  println("Writing to $(fn)")
  mkpath(dirname(fn))
  fid = open(fn,"w+")
  @printf fid "%i %i\n" size(J,1) size(J,2)
  for i in 1:size(J,1)
    for j in 1:size(J,2)
      @printf fid "%f " J[i,j]
    end
    @printf fid "\n"
  end
  close(fid)
end

function write_times(fn,tf,tJ)
  println("Writing to $(fn)")
  fid = open(fn,"w")
  @printf fid "%f %f\r\n" tf tJ
  @printf fid "tf tJ\r\n"
  close(fid)
end
