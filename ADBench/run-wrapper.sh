#!/bin/bash

# init values
RUN=0
PLOT=0
USAGE_MESSAGE="Usage: ./run-wrapper.sh ([-r|--run-all] || [-p|--plot-graphs] || [-h|--help]) args"

case $1 in
    -r|--run-all)
        RUN=1
        shift # pop first argument from $@
    ;;
    -p|--plot-graphs)
        PLOT=1
        shift # pop first argument from $@
    ;;
    -h|--help)
        echo $USAGE_MESSAGE
        exit 0
    ;;
    *)
        echo $USAGE_MESSAGE
        exit 0
    ;;
esac

if ((RUN)) ; then
    echo "Executing:" "pwsh" "run-all.ps1" "$@"
    "pwsh" "run-all.ps1" "$@"
fi

if ((PLOT)) ; then
    echo "Executing:" "python3" "plot_graphs.py" "$@"
    "python3" "plot_graphs.py" "$@"
fi