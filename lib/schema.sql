DROP TABLE IF EXISTS jenkins_test_stats;
CREATE TABLE jenkins_test_stats(
  job_id INT NOT NULL,
  class_name CHAR(200) NOT NULL,
  name CHAR(512) NOT NULL,
  passed BOOLEAN NOT NULL,
  status CHAR(10) NOT NULL,
  duration REAL NOT NULL,
  duration_share REAL NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL);
