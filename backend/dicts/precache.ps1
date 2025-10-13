$backend = "http://localhost:3000"
$outdir  = "C:\Users\WhatsApp\Desktop\traductor\backend\"

$files = @{
  "en" = "C:\Users\WhatsApp\Desktop\traductor\backend\palabras.txt"
  "es" = "$outdir\en_to_es.txt"
  "ja" = "$outdir\en_to_ja.txt"
  "ko" = "$outdir\en_to_ko.txt"
  "zh" = "$outdir\en_to_zh.txt"
}

$languages = @("en","es","ja","ko","zh")

foreach ($src in $languages) {
  $file = $files[$src]
  $tgts = ($languages | Where-Object { $_ -ne $src }) -join ","
  python precache.py `
    --backend $backend `
    --source $src `
    --targets $tgts `
    --file $file `
    --outdir $outdir `
    --workers 16 --timeout 20 --shuffle
}
