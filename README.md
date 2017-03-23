# Using

1: Download the necessary artifacts and generate the report!

```
make JOB=marathon-unstable-loop AUTH=user:token -j 8
```

Report text file will be found at `marathon-loop-tests/report.txt`

## Other recipes

If you'd like to download a subset of files and run a report for a specific job:

```
make JOB=public-test-marathon-phabricator IDS="$(seq 806 812 | xargs echo)"
```

Then, you can tell make to not download anymore:

```
make JOB=public-test-marathon-phabricator ignore
```

Then run it

```
make JOB=public-test-marathon-phabricator
```

Note that if you already have downloaded jobs in a previous invokation of make, then those will be included in the report. Run this to purge out all downloaded job results:

```
make JOB=public-test-marathon-phabricator purge
```

### JQ commands

See failed suites for a test containing some string:

```
jq 'map(select(.failure | contains("ping")))' marathon-unstable-loop/failures-by-test.json
```

# Visualizations

To visualize the dataset, you will need R installed. Because many of the dependencies have native extensions, you should install a version against which you can compile. For Mac OS X, `brew install R` is a good option.

As a pre-requisite, you need to install some packages. See the comment at the top of `viz.R`. Paste in each of these install commands (without the comment prefix `##`) in a fresh `R` terminal (launched simply by typing `R` in your console).

Once installed, you can render the visualizations like:

```
make JOB=marathon-unstable-loop AUTH=user:token viz
```
