#!/bin/bash

. lib/sql-common.sh

if [ -z "$1" ]; then
  echo "Usage: $0 [base_folder] [job_name]"
fi

BASE_FOLDER=$(cd "$1"; pwd)
TABLE_PREFIX=$(table-prefix "$1")

cat <<-EOF
COPY ${TABLE_PREFIX}_suite_stats FROM '${BASE_FOLDER}/flattened-suite.tsv' CSV HEADER DELIMITER E'\t';

COPY ${TABLE_PREFIX}_test_stats FROM '${BASE_FOLDER}/flattened-detail.tsv' CSV HEADER DELIMITER E'\t';
EOF
