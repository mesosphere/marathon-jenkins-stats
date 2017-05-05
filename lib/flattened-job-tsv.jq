["job_id", "duration", "non_empty", "total_count", "fail_count", "pass_count", "skip_count", "timestamp"] as $headers |
(input_filename | capture("^.+/(?<id>\\d+).json$") | .id | tonumber) as $id |
[$id,
 .duration,
 (if (.empty or .empty == null) then 0 else 1 end),
 .failCount + .passCount + .skipCount,
 .failCount,
 .passCount,
 .skipCount,
 (.suites | map(.timestamp) | min) + "Z"
 ] as $body |
$headers, $body | @tsv
