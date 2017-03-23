.PHONY: default all download clean purge load-into-postgres

default: all

JOB=public-marathon-unstable
AUTH:=
ifneq ($(AUTH),)
AUTH_ARGS:=--user "$(AUTH)"
endif
FETCH_COMMAND:=curl $(AUTH_ARGS) "https://jenkins.mesosphere.com/service/jenkins/view/Marathon/job/$(JOB)/api/json?pretty=true&allBuilds=true" | jq '.builds | map(.number | tostring) | .[1:] | join(" ")' -r
IDS:=$(shell $(FETCH_COMMAND))
EXISTING_IDS:=$(notdir $(basename .json, $(wildcard $(JOB)/builds/*.json)))
FILES:=$(foreach ID,$(IDS),$(JOB)/builds/$(ID).json)

clean:
	rm -f $(JOB)/failures-by-test.json $(JOB)/summary.txt $(JOB)/failures.json $(JOB)/flattened*
purge:
	rm -rf $(JOB)

$(JOB)/builds:
	mkdir -p $(JOB)/builds

$(JOB)/flattened-detail:
	mkdir -p $(JOB)/flattened-detail
$(JOB)/flattened-suite:
	mkdir -p $(JOB)/flattened-suite

ignore:
	$(foreach file, $(FILES), [ ! -f $(file) ] && echo '{"suites": []}' > $(file); )

$(subst %,\%,$(JOB))/builds/%.json: | $(JOB)/builds
	bin/grab-job $(AUTH_ARGS) -f "https://jenkins.mesosphere.com/service/jenkins/view/Marathon/job/$(JOB)/$(basename $(@F))/testReport/api/json?pretty=true" > $@.tmp
	mv $@.tmp $@

$(subst %,\%,$(JOB))/flattened-detail/%.tsv: $(subst %,\%,$(JOB))/builds/%.json | $(JOB)/flattened-detail
	jq -r -f lib/flattened-detail-tsv.jq $< > $@.tmp 
	mv $@.tmp $@

$(JOB)/flattened-detail.tsv: $(foreach ID,$(IDS) $(EXISTING_IDS),$(JOB)/flattened-detail/$(ID).tsv)
	bin/concat-csv $(JOB)/flattened-detail/*.tsv > $@.tmp
	mv $@.tmp $@

$(subst %,\%,$(JOB))/flattened-suite/%.tsv: $(subst %,\%,$(JOB))/builds/%.json | $(JOB)/flattened-suite
	jq -r -f lib/flattened-suite-tsv.jq $< > $@.tmp 
	mv $@.tmp $@

$(JOB)/flattened-suite.tsv: $(foreach ID,$(IDS) $(EXISTING_IDS),$(JOB)/flattened-suite/$(ID).tsv)
	bin/concat-csv $(JOB)/flattened-suite/*.tsv > $@.tmp
	mv $@.tmp $@

load-into-postgres: $(JOB)/flattened-detail.tsv
	cat lib/schema.sql | psql
	psql -c "COPY jenkins_test_stats FROM '$$(pwd)/$(JOB)/flattened-detail.tsv' CSV HEADER"

download: $(FILES)

$(JOB)/failures.json: $(FILES)
	bin/summarize-failure-files $(JOB)/builds/*.json | jq . -s > $@.tmp
	mv $@.tmp $@

$(JOB)/failures-by-test.json: $(JOB)/failures.json
	cat $(JOB)/failures.json | jq 'map(.id as $$v | (.failures[] | {failure: ., job: $$v})) | group_by(.failure) | map({ failure: (.[0].failure), jobs: (map(.job) | sort)})' > $@.tmp
	mv $@.tmp $@

$(JOB)/summary.txt: $(JOB)/failures.json
	cat $(JOB)/failures.json | jq '.[] | .failures[] | .' -r | sort | uniq -c | sort -n | tee $@.tmp
	echo "Sample size: $$(jq 'map(select(.suiteRan == true)) | length' $(JOB)/failures.json)" | tee -a $@.tmp
	mv $@.tmp $@

viz: $(JOB)/flattened-suite.tsv
	JOB=$(JOB) R --no-save < viz.R
all: $(JOB)/summary.txt $(JOB)/failures-by-test.json
