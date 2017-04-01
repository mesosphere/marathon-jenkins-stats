(input_filename | capture("^.+/(?<id>\\d+).json$") | .id | tonumber) as $id |
.duration as $totalduration |
(.suites | map(.cases[] | .duration) | add) as $suitedurations |
["job_id", "package", "class_name", "name", "passed", "status", "duration", "duration_share", "timestamp"] as $headers |
.suites |
map((.timestamp + "Z") as $timestamp |
    .cases[] |
     (.className | split(".")) as $className |
    [$id,
     ($className[0:-1] | join(".")),
     ($className[-1]),
     .name[0:511],
     if (.status != "FAILED" and .status != "REGRESSION") then 1 else 0 end,
     .status,
     .duration,
     ((.duration / $suitedurations) * $totalduration),
     $timestamp]) as $rows |
$headers, $rows[] | @tsv


