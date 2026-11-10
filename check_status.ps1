$r = Invoke-RestMethod -Uri "https://api.github.com/repos/GreenSoftSachi/green-excel/actions/runs/42857998306"
Write-Output "Status: $($r.status) | Conclusion: $($r.conclusion)"
$j = Invoke-RestMethod -Uri "https://api.github.com/repos/GreenSoftSachi/green-excel/actions/runs/42857998306/jobs"
$j.jobs[0].steps | Select-Object name, status, conclusion | Format-Table -AutoSize
