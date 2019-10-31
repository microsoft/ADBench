# ADBench Docker

You may use docker images of the ADBench project without having to install dependencies on your PC.

## Build docker image

1. Clone repository
2. Add nessasary AD tools
3. Run `docker build -f <dockerfile name> -t <docker image name> .`  
   e.g. `docker build -f some.Dockerfile -t adb-docker .`

## Run docker image

1. Create folder for results
2. Run docker image with proper arguments  
   - Option `-r|--run` to run benchmark (execute `run-all.ps1`)  
   e.g. `docker run -v /folder/for/results:/adb/tmp/ adb-docker -r -tools "Manual"`  
   - Option `-p|--plot` to plot graphs (execute `plot_graphs.py`)  
   e.g. `docker run -v /folder/for/results:/adb/tmp/ adb-docker -p --save`  
   - Option `-t|--ctest` to perform _GTEST_ (execute `ctest`)  
   e.g. `docker run adb-docker -t`

Option `-v /folder/for/results:/adb/tmp/` means that `/folder/for/results` should be mount to `/adb/tmp/` directory inside docker image.

Also you may want to use some `docker run` options:
```
-t   : Allocate a pseudo-tty
-i   : Keep STDIN open even if not attached
--rm : Automatically remove the container when it exits
```
E.g. `docker run -it --rm -v /folder/for/results:/adb/tmp/ adb-docker -r`

You may find more information here: https://docs.docker.com/engine/reference/run/

## Add dependencies to docker

If you need additional dependencies to be added, you should add docker build steps before `COPY` stage, e.g.:
```
# other build steps
WORKDIR /utils/additional_tool
RUN <some linux commands, separated with &&>
COPY . .
```
`WORKDIR` is used to change directory during docker build.
Using `&&` to separate commands is a good idea, because if one of the commands fails, the docker build also fails.
Also it is better to remove temporary data during docker build step to decrease docker image size.

You may find more information here: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/