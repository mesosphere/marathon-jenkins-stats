(input_filename | capture("^.+/(?<id>\\d+).json$") | .id | tonumber) as $id |
.duration as $totalduration |
(.suites | map(.duration) | add) as $suitedurations |
["job_id", "package", "class_name", "tests_total", "tests_passed", "passed", "duration", "timestamp"] as $headers |
.suites |
map((if (.timestamp == null) then "" else .timestamp + "Z" end) as $timestamp |
    (.cases | length) as $total |
    (.cases | map(if (.status != "FAILED" and .status != "REGRESSION") then 1 else 0 end) | add) as $passes |
    ((.name) | split(".")) as $name |
    [$id,
     ($name[0:-1] | join(".")),
     ($name[-1]),
     $total,
     $passes,
     (if $total == $passes then 1 else 0 end),
     .duration,
     $timestamp]) as $rows |
$headers, $rows[] | @tsv
