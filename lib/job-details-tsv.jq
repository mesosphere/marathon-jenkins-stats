# klsdjf
["job_id", "result", "duration", "branch", "rev", "timestamp"] as $headers |
. | map(
        (.actions | map(.buildsByBranchName | select(. != null) | to_entries[] | .value)[0]) as $action |
        [.id,
         .result,
         .duration,
         ($action | .revision.branch[0].name),
         ($action | .revision.SHA1),
         (.timestamp / 1000 | gmtime | todate)]) as $rows |
$headers, $rows[] | @tsv
