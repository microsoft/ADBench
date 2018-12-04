python -m pip install --user matplotlib plotly

# I'm not sure that setting up vcvars is necessary in Azure Dev Ops.
# We have a VS2017 host so presumably it has all the paths set up
# already.
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
Install-Module -Name VCVars -Force -Verbose -Scope CurrentUser
set-vcvars (invoke-vcvars amd64)

# We have to run cmake thrice because the Boost compile always (I
# think) fails on the first run, sometimes fails on the second, and
# always succeeds on the third.  The problem is
#
# https://github.com/boostorg/build/issues/239
#
# and
#
# https://github.com/ruslo/hunter/issues/1223
#
# and I have no idea why subsequent runs work!
cmake -G "Ninja" "-DCMAKE_TOOLCHAIN_FILE=$Env:BUILD_SOURCESDIRECTORY\toolchain.cmake" '-DCMAKE_BUILD_TYPE="RelWithDebInfo"' .
cmake -G "Ninja" "-DCMAKE_TOOLCHAIN_FILE=$Env:BUILD_SOURCESDIRECTORY\toolchain.cmake" '-DCMAKE_BUILD_TYPE="RelWithDebInfo"' .
cmake -G "Ninja" "-DCMAKE_TOOLCHAIN_FILE=$Env:BUILD_SOURCESDIRECTORY\toolchain.cmake" '-DCMAKE_BUILD_TYPE="RelWithDebInfo"' .

ninja
powershell .\ADBench\run-all.ps1 -repeat 0 -nruns_J 10 -nruns_f 10 -time_limit 5 -gmm_d_vals 2,10,20,32,64 -gmm_k_vals 5,10,25,50,100,200
python ADBench/plot_graphs.py --save --plotly
cp -r "Documents/New Figures" "$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
Write-Host "##vso[artifact.upload containerfolder=;artifactname=Artifact;localpath=$Env:BUILD_ARTIFACTSTAGINGDIRECTORY;]$Env:BUILD_ARTIFACTSTAGINGDIRECTORY"
Write-Host "##vso[artifact.upload containerfolder=;artifactname=tmp;localpath=$Env:BUILD_SOURCESDIRECTORY\tmp;]$Env:BUILD_SOURCESDIRECTORY\tmp"
