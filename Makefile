.PHONY: default all download clean purge load-into-postgres viz ignore clean-missing

default: all

JOB=public-marathon-unstable
AUTH:=
ifneq ($(AUTH),)
AUTH_ARGS:=--user "$(AUTH)"
endif
FETCH_COMMAND:=curl $(AUTH_ARGS) "https://jenkins.mesosphere.com/service/jenkins/view/Marathon/job/$(JOB)/api/json?pretty=true&allBuilds=true" | jq '.builds | map(.number | tostring) | .[1:] | join(" ")' -r
IDS:=$(shell $(FETCH_COMMAND))

FOLDER:=$(subst %,_,$(JOB))
FILES:=$(foreach ID,$(IDS),$(FOLDER)/builds/$(ID).json)
EXISTING_IDS:=$(notdir $(basename .json, $(wildcard $(FOLDER)/builds/*.json)))

# We create temporary files when Jenkins 404's in order to not cause jq to crash. This target clears them.
clean-missing:
	find $(FOLDER)/builds -name *.json -type f -size -20c -exec echo rm -f {} \;

# Clean all interim files EXCEPT downloaded build data
clean:
	rm -f $(FOLDER)/failures-by-test.json $(FOLDER)/summary.txt $(FOLDER)/failures.json $(FOLDER)/flattened*

# Clean everything. build data included
purge:
	rm -rf $(FOLDER)

$(FOLDER)/builds:
	mkdir -p $(FOLDER)/builds

$(FOLDER)/flattened-detail:
	mkdir -p $(FOLDER)/flattened-detail

$(FOLDER)/flattened-suite:
	mkdir -p $(FOLDER)/flattened-suite

ignore:
	$(foreach file, $(FILES), [ ! -f $(file) ] && echo '{"suites": []}' > $(file); )

$(FOLDER)/builds/%.json: | $(FOLDER)/builds
	bin/grab-job $(AUTH_ARGS) -f "https://jenkins.mesosphere.com/service/jenkins/view/Marathon/job/$(JOB)/$(basename $(@F))/testReport/api/json?pretty=true" > $@.tmp
	mv $@.tmp $@

$(FOLDER)/flattened-detail/%.tsv: $(FOLDER)/builds/%.json | $(FOLDER)/flattened-detail
	jq -r -f lib/flattened-detail-tsv.jq $< > $@.tmp 
	mv $@.tmp $@

$(FOLDER)/flattened-detail.tsv: $(foreach ID,$(IDS) $(EXISTING_IDS),$(FOLDER)/flattened-detail/$(ID).tsv)
	bin/concat-csv $(FOLDER)/flattened-detail/*.tsv > $@.tmp
	mv $@.tmp $@

$(FOLDER)/flattened-suite/%.tsv: $(FOLDER)/builds/%.json | $(FOLDER)/flattened-suite
	jq -r -f lib/flattened-suite-tsv.jq $< > $@.tmp 
	mv $@.tmp $@

$(FOLDER)/flattened-suite.tsv: $(foreach ID,$(IDS) $(EXISTING_IDS),$(FOLDER)/flattened-suite/$(ID).tsv)
	bin/concat-csv $(FOLDER)/flattened-suite/*.tsv > $@.tmp
	mv $@.tmp $@

load-into-postgres: $(FOLDER)/flattened-suite.tsv $(FOLDER)/flattened-detail.tsv
	lib/schema.sql.sh "$(JOB)" | psql
	lib/load.sql.sh "$(FOLDER)" "$(JOB)" | psql

download: $(FILES)

$(FOLDER)/failures.json: $(FILES)
	bin/summarize-failure-files $(FOLDER)/builds/*.json | jq . -s > $@.tmp
	mv $@.tmp $@

$(FOLDER)/failures-by-test.json: $(FOLDER)/failures.json
	cat $(FOLDER)/failures.json | jq 'map(.id as $$v | (.failures[] | {failure: ., job: $$v})) | group_by(.failure) | map({ failure: (.[0].failure), jobs: (map(.job) | sort)})' > $@.tmp
	mv $@.tmp $@

$(FOLDER)/summary.txt: $(FOLDER)/failures.json
	cat $(FOLDER)/failures.json | jq '.[] | .failures[] | .' -r | sort | uniq -c | sort -n | tee $@.tmp
	echo "Sample size: $$(jq 'map(select(.suiteRan == true)) | length' $(FOLDER)/failures.json)" | tee -a $@.tmp
	mv $@.tmp $@

viz: $(FOLDER)/flattened-suite.tsv
	JOB=$(FOLDER) R --no-save < viz.R
all: $(FOLDER)/summary.txt $(FOLDER)/failures-by-test.json
