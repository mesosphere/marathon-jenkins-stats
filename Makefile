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
	rm $(JOB)/report.txt
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

$(JOB)/report.txt: $(FILES)
	cat $(JOB)/builds/*.json | jq '.suites[] | .cases[] | select(.status == "FAILED" or .status == "REGRESSION") | .className + ":" + .name' -r | sort | uniq -c | sort -n | tee $@.tmp
	echo "Sample size: $$(cat $(JOB)/builds/*.json | jq -s 'map(.passCount != null) | map(select(.)) | length')" | tee -a $@.tmp
	mv $@.tmp $@

all: $(JOB)/report.txt
