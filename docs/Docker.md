# Docker

You may use docker images of the ADBench project without having to install all the [prerequisites](./BuildAndTest.md#prerequisites) on your PC.

## Building docker image

1. Clone the repository
2. Add your AD tools if necessary
3. Run `docker build -f <dockerfile name> -t <docker image name> .` from the root directory of the ADBench project  
   e.g. `docker build -f some.Dockerfile -t adb-docker .`

## Running docker image

1. Create a folder for results
2. Run the docker image with proper arguments.  
   At the docker image startup, the `/ADBench/run-wrapper.sh` script is executed. The following are possible launch options:  
   - Option `-r|--run` to run benchmark (execute [global runner script](./GlobalRunner.md))  
   e.g. `docker run -v /folder/for/results:/adb/tmp/ adb-docker -r -tools "Manual"`  
   - Option `-p|--plot` to plot graphs (execute [plot script](./PlotCreating.md))  
   e.g. `docker run -v /folder/for/results:/adb/tmp/ adb-docker -p --save`  
   - Option `-t|--ctest` to perform _GTEST_ (execute `ctest`)  
   e.g. `docker run adb-docker -t`

Option `-v /folder/for/results:/adb/tmp/` means that `/folder/for/results` should be mount to `/adb/tmp/` directory inside docker image.

You can also use some `docker run` options:
```
-t   : Allocate a pseudo-tty
-i   : Keep STDIN open even if not attached
--rm : Automatically remove the container when it exits
```
E.g. `docker run -it --rm -v /folder/for/results:/adb/tmp/ adb-docker -r`

You may find more information here: https://docs.docker.com/engine/reference/run/

## Adding dependencies

If you need additional dependencies to be installed into the docker image, you should add docker build steps to the `/Dockerfile` before the `COPY` stage, e.g.:
```
# other build steps

WORKDIR /utils/additional_tool
RUN <some linux commands, separated with &&>

WORKDIR /adb
# Copy code to /adb (.dockerignore exclude some files)
COPY . .
```
`WORKDIR` is used to change directory during docker build.
Using `&&` to separate commands is a good idea, because if one of the commands fails, the docker build also fails.
Also it is better to remove temporary data during docker build step to decrease docker image size.

You may find more information here: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/