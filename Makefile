.PHONY: default all download clean purge

default: all

JOB=public-marathon-unstable
AUTH:=
ifneq ($(AUTH),)
AUTH_ARGS:=--user "$(AUTH)"
endif
FETCH_COMMAND:=curl $(AUTH_ARGS) "https://jenkins.mesosphere.com/service/jenkins/view/Marathon/job/$(JOB)/api/json?pretty=true&allBuilds=true" | jq '.builds | map(.number | tostring) | .[1:] | join(" ")' -r
IDS:=$(shell $(FETCH_COMMAND))

FILES:=$(foreach ID,$(IDS),$(JOB)/builds/$(ID).json)

thing:
	echo $(FETCH_COMMAND)
clean:
	rm -f $(JOB)/failures-by-job.json $(JOB)/summary.txt $(JOB)/failures.json
purge:
	rm -rf $(JOB)

$(JOB)/builds:
	mkdir -p $(JOB)/builds

ignore:
	$(foreach file, $(FILES), [ ! -f $(file) ] && echo '{"suites": []}' > $(file); )

$(JOB)/builds/%.json: | $(JOB)/builds
	bin/grab-job $(AUTH_ARGS) -f "https://jenkins.mesosphere.com/service/jenkins/view/Marathon/job/$(JOB)/$(basename $(@F))/testReport/api/json?pretty=true" > $@.tmp
	mv $@.tmp $@

download: $(FILES)

$(JOB)/failures.json: $(FILES)
	jq '{id: (input_filename | capture("^.+/(?<id>\\d+).json$$") | .id | tonumber), failures: (.suites | map(.cases[] | select(.status == "FAILED" or .status == "REGRESSION") | .className + ":" + .name)), suiteRan: (.passCount != null)}' $(JOB)/builds/*.json | jq . -s > $@.tmp
	mv $@.tmp $@

$(JOB)/failures-by-job.json: $(JOB)/failures.json
	cat $(JOB)/failures.json | jq 'map(.id as $$v | (.failures[] | {failure: ., job: $$v})) | group_by(.failure) | map({ failure: (.[0].failure), jobs: (map(.job) | sort)})' > $@.tmp
	mv $@.tmp $@

$(JOB)/summary.txt: $(JOB)/failures.json $(JOB)/details.txt
	cat $(JOB)/failures.json | jq '.[] | .failures[] | .' -r | sort | uniq -c | sort -n | tee $@.tmp
	echo "Sample size: $$(jq 'map(select(.suiteRan == true)) | length' $(JOB)/failures.json)" | tee -a $@.tmp
	mv $@.tmp $@

all: $(JOB)/summary.txt $(JOB)/failures-by-job.json
