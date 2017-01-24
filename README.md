# Using

1: Download the necessary artifacts:

```
make JOB=marathon-loop-tests AUTH=user:token download -j 8 -k
```


2: Some jobs don't have results and will probably fail to download. The Makefile
doesn't detect the difference. So, once you've downloaded everything that can,
then ignore the rest:

```
make JOB=marathon-loop-tests AUTH=user:token ignore
```

3: Now, generate the report

```
make JOB=marathon-loop-tests AUTH=user:token
```

## Other recipes

If you'd like to download a subset of files and run a report for a specific job:

```
make JOB=public-test-marathon-phabricator IDS="$(seq 806 812 | xargs echo)"
```

Note that if you already have downloaded jobs in a previous invokation of make, then those will be included in the report. Run this to purge out all downloaded job results:

```
make JOB=public-test-marathon-phabricator purge
```
