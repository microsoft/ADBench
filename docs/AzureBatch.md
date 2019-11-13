# Azure Batch All Tool Running

## Description

This document describes the all tool running process that is executed once a week and stores the results to the Azure Blob container from which they can be observed by the [ADBench Web Viewer](#Web-viewer). All paths in this document are specified relative to the repository root.

### General info
The process is designed as an [Azure Batch](https://docs.microsoft.com/en-us/azure/batch/) job that is scheduled weekly. This job starts the script `ADBench/AzureBatch/runallscript.sh` on the pool node. This script clones the repository from GitHub, creates a Docker container, and runs all tools. After run completion the script runs graph creating and then stores the result plots to the output directory from which they are uploaded to the [Azure Storage](https://docs.microsoft.com/en-us/azure/storage/).

### Recalculating check
If graphs have been already created for the last commit, then the script finishes and does nothing. To check that the last commit has been handled, the process stores its hash to the file called `last_commit.txt` located in the blob container root. Before the script starting, the job downloads this file to the pool node. The script compares the file content with the latest repository master branch commit hash. In case of equality it finishes. Exit code the script returns in such a case is not zero because zero exit code is a signal to the job to upload the result graphs to the storage. In case of hash difference the script writes the current handled commit hash to the file `last_commit.txt`, and then the job uploads this file to the blob container.

### The script
`ADBench/AzureBatch/runallscript.sh` is a bash script that is designed for *Ubuntu 18.04*. It has descriptive comments, so you can find more information about its behaviour in them. The script returns the following exit codes:

| Exit code | The case when it is returned |
| -- | -- |
| 0 | Script ran successfully and created all graphs |
| 1 | Graph creation is not needed becuase for the current commit it has been done |
| 2 | Git problem |
| 3 | Docker installation problem |
| 4 | Docker daemon activating problem |
| 5 | Docker container building problem |
| 6 | ADBench tests failure |
| 7 | Tool running failure |
| 8 | Graph creation failure |

### Web viewer
The special application is used for the process result browsing. Its source is located in the directory `ADBench/ADBenchWebViewer`. This application looks through the blob container, which URL is defined in its `appsettings.json` file, and creates HTML pages for the result observing. The viewer could be published in Azure as a hosted [Web Application](https://docs.microsoft.com/en-us/azure/app-service/) (see [instruction](https://docs.microsoft.com/en-us/azure/app-service/app-service-web-get-started-dotnet#publish-your-web-app)).

## Creating a new Azure Batch

If you want to deploy a new Azure Batch Job Schedule, that will execute the run all process weekly, do the following steps:

1. Create an [Azure Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-quickstart-create-account?tabs=azure-portal). Set up a blob container in which the run all process will store the results. Create an empty file `last_commit.txt` in the container root.
2. Create an [Azure Batch Account](https://docs.microsoft.com/en-us/azure/batch/batch-account-create-portal).
3. Create a [pool](https://docs.microsoft.com/en-us/azure/batch/batch-api-basics#pool). Chose *Ubuntu 18.04* as an image. As far as the process requires only one node, you can use this [autoscale formula](https://docs.microsoft.com/en-us/azure/batch/batch-automatic-scaling) for the pool:
    ```
    $TargetDedicatedNodes = (max($PendingTasks.GetSample(TimeInterval_Minute * 5)) > 0.0) ? 1 : 0
    ```
    Thus, pool will create a node if there was a pending task in the last 5 minutes and will remove node otherwise.
4. Create an [application package](https://docs.microsoft.com/en-us/azure/batch/batch-application-packages) named _runallscript_ with version _1_ contains a zip with the file `ADBench/AzureBatch/runallscript.sh`. Set its default version to _1_.
5. Create a [job schedule](https://docs.microsoft.com/en-us/azure/batch/batch-api-basics#scheduled-jobs) using the JSON file `ADBench/AzureBatch/schedule.json` (you can use both [REST API](https://docs.microsoft.com/en-us/rest/api/batchservice/jobschedule/add) or [Azure Portal](https://portal.azure.com) for this), setting these missed properties with respective values (use info of the blob container created in the step 1):

    | Property | Value description |
    | -- | -- |
    | jobSpecification.resourceFiles[0].httpUrl | URL of the file `last_commit.txt` in the blob container root |
    | jobSpecification.outputFiles[0].destination.container.containerUrl | URL of the blob container |

6. If you want to see the results of the new process in the ADBench Web Viewer, set the value of the property `blobContainerUrl` in a JSON file `ADBench/ADBenchWebViewer/ADBenchWebViewer/appsettings.json` to the URL of the blob container created in the step 1. Then the web app will show info from your new container.