#!/bin/bash

. lib/sql-common.sh

if [ -z "$1" ]; then
  echo "Usage: $0 [base_folder] [job_name]"
fi

TABLE_PREFIX="$(table-prefix "$1")"
cat <<-EOF
DROP TABLE IF EXISTS ${TABLE_PREFIX}_test_stats;
CREATE TABLE ${TABLE_PREFIX}_test_stats(
  job_id INT NOT NULL,
  package CHAR(200) NOT NULL,
  class_name CHAR(200) NOT NULL,
  name CHAR(512) NOT NULL,
  passed BOOLEAN NOT NULL,
  status CHAR(10) NOT NULL,
  duration REAL NOT NULL,
  duration_share REAL NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL);
EOF

cat <<-EOF
DROP TABLE IF EXISTS ${TABLE_PREFIX}_suite_stats;
CREATE TABLE ${TABLE_PREFIX}_suite_stats(
  job_id INT NOT NULL,
  package CHAR(200) NOT NULL,
  class_name CHAR(200) NOT NULL,
  tests_total INT NOT NULL,
  tests_passed INT NOT NULL,
  passed BOOLEAN NOT NULL,
  duration REAL NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL);
EOF
