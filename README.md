# Using

1: Download the necessary artifacts and generate the report!

```
$ make JOB=marathon-unstable-loop AUTH=user:token -j 8
```

Report text file will be found at `marathon-loop-tests/report.txt`

## Other recipes

If you'd like to download a subset of files and run a report for a specific job:

```
$ make JOB=public-test-marathon-phabricator IDS="$(seq 806 812 | xargs echo)"
```

Then, you can tell make to not download anymore:

```
$ make JOB=public-test-marathon-phabricator ignore
```

Then run it

```
$ make JOB=public-test-marathon-phabricator
```

Note that if you already have downloaded jobs in a previous invokation of make, then those will be included in the report. Run this to purge out all downloaded job results:

```
$ make JOB=public-test-marathon-phabricator purge
```

### JQ commands

See failed suites for a test containing some string:

```
$ jq 'map(select(.failure | contains("ping")))' marathon-unstable-loop/failures-by-test.json
```

# Load into Postgres

You can load the data into postgres. (I haven't tested this with a remote instance, it may require that the data file is on a folder local to the master)

1. Make sure `psql` can connect to the appropriate database. You can set the following environment variables

# Visualizations

To visualize the data set, you will need R installed. Because many of the dependencies have native extensions, you should install a version against which you can compile. For Mac OS X:
```
$ brew install R
```
is a good option.

As a pre-requisite, you need to install some packages. See the comment at the top of `viz.R`. Paste in each of these install commands (without the comment prefix `##`) in a fresh `R` terminal (launched simply by typing `R` in your console). You can also install multiple packages with one command e.g.:
```
> install.packages(c("reshape2", "plyr", "devtools", ...))
```
Once installed, you can render the visualizations like:

```
$ make JOB=marathon-unstable-loop AUTH=user:token viz
```

Some graphs are specfic to one job, e.g. `duration.pdf` visualizes the render
times of each test suite for one test run. By default the build with the
highest job id is visualized. However, one can specify a job id as follows:

```
$ make JOB=marathon-unstable-loop VIZ_JOB_ID-1337 AUTH=user:token viz
```
