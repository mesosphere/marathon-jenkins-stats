["job_id", "result", "duration", "branch", "rev", "timestamp"] as $headers |
. | map(if (.id == null) then
        null
        else
        (.id | tonumber) as $id |
        ((.actions | map(.buildsByBranchName | select(. != null) | to_entries[] | .value)) | map(select(.buildNumber == $id))[0]) as $action |
        [.id,
         .result,
         .duration,
         ($action | .revision.branch[0].name),
         ($action | .revision.SHA1),
         (.timestamp / 1000 | gmtime | todate)]
        end
        ) | map(select(. != null)) as $rows |
$headers, $rows[] | @tsv
