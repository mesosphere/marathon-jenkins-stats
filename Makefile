.PHONY: default all download clean purge load-into-postgres viz ignore clean-missing

default: all

JOB=public-marathon-unstable
AUTH:=
ifneq ($(AUTH),)
AUTH_ARGS:=--user "$(AUTH)"
endif
FETCH_COMMAND:=curl $(AUTH_ARGS) "https://jenkins.mesosphere.com/service/jenkins/view/Marathon/job/$(JOB)/api/json?pretty=true&allBuilds=true" | jq '.builds | map(.number | tostring) | .[1:] | join(" ")' -r
IDS:=$(shell $(FETCH_COMMAND))
EXISTING_IDS:=$(notdir $(basename .json, $(wildcard $(JOB)/builds/*.json)))

SAFE_JOB:=$(subst %,_,$(JOB))
FILES:=$(foreach ID,$(IDS),$(SAFE_JOB)/builds/$(ID).json)

# We create temporary files when Jenkins 404's in order to not cause jq to crash. This target clears them.
clean-missing:
	find $(SAFE_JOB)/builds -name *.json -type f -size -20c -exec echo rm -f {} \;

# Clean all interim files EXCEPT downloaded build data
clean:
	rm -f $(SAFE_JOB)/failures-by-test.json $(SAFE_JOB)/summary.txt $(SAFE_JOB)/failures.json $(SAFE_JOB)/flattened*

# Clean everything. build data included
purge:
	rm -rf $(SAFE_JOB)

$(SAFE_JOB)/builds:
	mkdir -p $(SAFE_JOB)/builds

$(SAFE_JOB)/flattened-detail:
	mkdir -p $(SAFE_JOB)/flattened-detail

$(SAFE_JOB)/flattened-suite:
	mkdir -p $(SAFE_JOB)/flattened-suite

ignore:
	$(foreach file, $(FILES), [ ! -f $(file) ] && echo '{"suites": []}' > $(file); )

$(SAFE_JOB)/builds/%.json: | $(SAFE_JOB)/builds
	bin/grab-job $(AUTH_ARGS) -f "https://jenkins.mesosphere.com/service/jenkins/view/Marathon/job/$(JOB)/$(basename $(@F))/testReport/api/json?pretty=true" > $@.tmp
	mv $@.tmp $@

$(SAFE_JOB)/flattened-detail/%.tsv: $(SAFE_JOB)/builds/%.json | $(SAFE_JOB)/flattened-detail
	jq -r -f lib/flattened-detail-tsv.jq $< > $@.tmp 
	mv $@.tmp $@

$(SAFE_JOB)/flattened-detail.tsv: $(foreach ID,$(IDS) $(EXISTING_IDS),$(SAFE_JOB)/flattened-detail/$(ID).tsv)
	bin/concat-csv $(SAFE_JOB)/flattened-detail/*.tsv > $@.tmp
	mv $@.tmp $@

$(SAFE_JOB)/flattened-suite/%.tsv: $(SAFE_JOB)/builds/%.json | $(SAFE_JOB)/flattened-suite
	jq -r -f lib/flattened-suite-tsv.jq $< > $@.tmp 
	mv $@.tmp $@

$(SAFE_JOB)/flattened-suite.tsv: $(foreach ID,$(IDS) $(EXISTING_IDS),$(SAFE_JOB)/flattened-suite/$(ID).tsv)
	bin/concat-csv $(SAFE_JOB)/flattened-suite/*.tsv > $@.tmp
	mv $@.tmp $@

load-into-postgres: $(SAFE_JOB)/flattened-suite.tsv $(SAFE_JOB)/flattened-detail.tsv
	lib/schema.sql.sh "$(JOB)" | psql
	lib/load.sql.sh "$(SAFE_JOB)" "$(JOB)" | psql

download: $(FILES)

$(SAFE_JOB)/failures.json: $(FILES)
	bin/summarize-failure-files $(SAFE_JOB)/builds/*.json | jq . -s > $@.tmp
	mv $@.tmp $@

$(SAFE_JOB)/failures-by-test.json: $(SAFE_JOB)/failures.json
	cat $(SAFE_JOB)/failures.json | jq 'map(.id as $$v | (.failures[] | {failure: ., job: $$v})) | group_by(.failure) | map({ failure: (.[0].failure), jobs: (map(.job) | sort)})' > $@.tmp
	mv $@.tmp $@

$(SAFE_JOB)/summary.txt: $(SAFE_JOB)/failures.json
	cat $(SAFE_JOB)/failures.json | jq '.[] | .failures[] | .' -r | sort | uniq -c | sort -n | tee $@.tmp
	echo "Sample size: $$(jq 'map(select(.suiteRan == true)) | length' $(SAFE_JOB)/failures.json)" | tee -a $@.tmp
	mv $@.tmp $@

viz: $(SAFE_JOB)/flattened-suite.tsv
	JOB=$(SAFE_JOB) R --no-save < viz.R
all: $(SAFE_JOB)/summary.txt $(SAFE_JOB)/failures-by-test.json
