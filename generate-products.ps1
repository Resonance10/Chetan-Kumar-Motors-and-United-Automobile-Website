$inFile = "C:\Open Code Projects\Chetan Kumar Motor & United Auto Website\arranged_stock.txt"
$outFile = "C:\Open Code Projects\Chetan Kumar Motor & United Auto Website\products.js"

$lines = Get-Content $inFile

function Get-Category($name, $vehicle) {
    $text = ($name + " " + $vehicle).ToLower()
    # tyre
    if ($text -match '(?i)\btyre\b|\btire\b|battelug') { return 'tyre' }
    # jcb / construction
    if ($text -match '(?i)\bjcb\b|excavator|backhoe|loader\b|dozer|compactor|grader|forklift') { return 'jcb' }
    # tractor (check vehicle column first)
    if ($vehicle -match '(?i)\btractor\b|massey|ferguson|eicher|escorts|farmtrac|powertrac|swaraj|kubota|new.holland|preet|solis|tafe|forder|sonalika|kukje|same\b|lamborghini|deutz|fiat\b|ford\b|mahindra.*tractor') { return 'tractor' }
    if ($name -match '(?i)\btractor\b|pto\s|p.t.o|hydraulic\s*(pump|cylinder)|steering.*(box|sector)|radiator.*tractor') { return 'tractor' }
    # two-wheeler
    if ($vehicle -match '(?i)activa|scooter|scooty|splendor|passion\b|shine|unicorn|pulsar|platina|apache|fz\b|rx\b|ct\s*(100|110)|aviator|dream.*yuga|hunk|xtreme|karizma|cbz|sp\s*125|hf.*deluxe|cd.*dawn|cd.*100|deluxe\b|tvs\s|bajaj\s|hero\s|honda.*(?:shine|unicorn|splendor|dream)|motorcycle|\bbike\b') { return 'twowheeler' }
    if ($name -match '(?i)chain.*sprocket|brake.*shoe|clutch.*(?:cable|plate)|cvt.*belt|yoke\b|handlebar|speedometer|silencer|muffler|indicator.*assy|headlight.*assy|tail.*light|shock.*absorber|swing.*arm|disc.*brake|caliper|master.*cylinder|wheel.*cylinder|spoke|rim\b|tube.*tyre|piston.*ring.*bike') { return 'twowheeler' }
    if ($vehicle -match '(?i)pleasure|maestro|destini|vespa|ape\b|nano') { return 'twowheeler' }
    # farm
    if ($name -match '(?i)cultivator|tiller|rotavator|harrow|plough|plow|leveller|baler|thresher|sprayer|irrigation|submersible|pump\s+(?:set|body|impeller)|borewell|ridger|furrower') { return 'farm' }
    if ($vehicle -match '(?i)farm|\bagriculture\b|tiller|cultivator|pump\s+(?:set|body)') { return 'farm' }
    # car default
    return 'car'
}

function Get-Icon($cat) {
    switch ($cat) {
        'car' { return 'fa-car' }
        'tractor' { return 'fa-tractor' }
        'farm' { return 'fa-tractor' }
        'tyre' { return 'fa-circle' }
        'jcb' { return 'fa-cogs' }
        'twowheeler' { return 'fa-motorcycle' }
        default { return 'fa-cogs' }
    }
}

function Escape-JS($s) {
    return ($s -replace '\\', '\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '' -replace "`t", '\t')
}

$id = 0
$stream = [System.IO.StreamWriter]::new($outFile, $false, [System.Text.Encoding]::UTF8)
$stream.WriteLine('const products = [')

foreach ($line in $lines) {
    # Skip obviously non-item lines
    if ($line.Trim() -eq '') { continue }
    
    $parts = $line -split ' \| ', 3
    if ($parts.Count -lt 1) { continue }
    
    $name = $parts[0].Trim()
    $vehicle = ""
    $brand = ""
    
    if ($parts.Count -ge 2) { $vehicle = $parts[1].Trim() }
    if ($parts.Count -ge 3) { $brand = $parts[2].Trim() }
    
    # If first column is empty, use second column as name
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = $vehicle
        $vehicle = ""
    }
    
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    
    # Skip footer lines
    if ($name -eq 'Remarks' -and [string]::IsNullOrWhiteSpace($vehicle) -and [string]::IsNullOrWhiteSpace($brand)) { continue }
    if ($name -match '^\d+$' -and $name.Length -le 4 -and [string]::IsNullOrWhiteSpace($vehicle) -and [string]::IsNullOrWhiteSpace($brand)) { continue }
    
    $id++
    $cat = Get-Category $name $vehicle
    $icon = Get-Icon $cat
    
    $eName = Escape-JS $name
    $eVehicle = Escape-JS $vehicle
    $eBrand = Escape-JS $brand
    
    $stream.Write("  {id:$id,name:`"$eName`",cat:`"$cat`",vehicle:`"$eVehicle`",icon:`"$icon`",stock:`"in`"}")
    # Write brand as img field (metadata), or just empty
    $stream.WriteLine(',')
}

$stream.WriteLine('];')
$stream.Close()

Write-Host "Generated $id products -> $outFile"
