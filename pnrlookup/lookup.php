<?php
/*
Copyright © 2016 Samuel Lidén Borell <samuel@kodafritt.se>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

header('Content-Type: text/html; charset=UTF-8');
error_reporting(E_ALL);
ini_set("display_errors", 1);

define('DB_LOCATION', 'pnr96.sqlite');



$swtr = array(0xC5 => 0x100, 0xC4 => 0x101, 0xD6 => 0x102);
function swedishcol($a, $b) {
    global $swtr;
    $a = utf8_decode($a);
    $b = utf8_decode($b);
    $alen = strlen($a);
    $blen = strlen($b);
    $minlen = min($alen, $blen);
    for ($i = 0; $i < $minlen; $i++) {
        $ac = ord($a[$i]);
        $bc = ord($b[$i]);
        if ($ac == 0xC9) $ac = 0x45; // É --> E
        if ($bc == 0xC9) $bc = 0x45; // É --> E
        if ($ac == $bc) continue;
        if ($ac <= 90 || $bc <= 90) {
            return $ac - $bc;
        } else {
            $ac = $swtr[$ac];
            $bc = $swtr[$bc];
            return $ac - $bc;
        }
    }
    return $alen - $blen;
}
/*function testsc($a,$b) {
    print "$a,$b = ".swedishcol($a,$b)."<br>\n";
}
testsc("A","B");
testsc("Z","Å");
testsc("Å","Ä");
testsc("Ä","Ö");*/

function swetoupper($s) {
    return str_replace(array("å","ä","ö","é","à"), array("Å","Ä","Ö","É","À"), strtoupper($s));
}

$db = new SQLite3(DB_LOCATION);
$db->createCollation('localecol', 'swedishcol');

$municipalityScb = isset($_GET['municipality']) ? intval($_GET['municipality']) : null;
$roadname = isset($_GET['roadname']) ? swetoupper(trim(strval($_GET['roadname']))) : '';
if (isset($_GET['roadname']) && $roadname !== $_GET['roadname']) {
    header('Location: lookup.php?municipality='.intval($municipalityScb).'&roadname='.urlencode($roadname));
    exit();
}

$search = 0;
if ($municipalityScb !== null && $roadname !== '') {
    $search = 1;
    $title = $roadname.' - Vägar med samma postnummer i PNR6';
    $infoHtml = '';
} else {
    $title = 'Sök närliggande vägar i PNR96';
    $infoHtml = '<p>Sök postnummerinfo i Postnummerkatalogen 1996</p>';
}

?>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title><?php echo htmlspecialchars($title); ?></title>
</head>
<body>
<?php echo $infoHtml; ?>
<form onsubmit="upper()">
<div>Kommun:
<select size="1" name="municipality">
<?php
$result = $db->query('SELECT municipalityScb, municipalityName FROM kommun ORDER BY municipalityName COLLATE localecol');
$muniName = null;
while ($row = $result->fetchArray(SQLITE3_NUM)) {
    $id = intval($row[0]);
    $name = strval($row[1]);
    if ($id == $municipalityScb) {
        $muniName = $name;
        $selected = ' selected';
    } else {
        $selected = '';
    }
    echo '<option value="'.htmlspecialchars($id).'"'.$selected.'>'.htmlspecialchars($name)."</option>\n";
}
$result->finalize();
?>
</select>
&nbsp;
Vägnamn: <input type="text" name="roadname" id="roadname" size="30" value="<?php echo htmlspecialchars($roadname); ?>" onblur="upper()">
&nbsp;
<input type="submit" value="Sök" onmousedown="upper()">
</div>
</form>
<?php

if ($search == 1) {
    $stmt = $db->prepare('SELECT postalCode, postalTown FROM pnr96 NATURAL JOIN postort2kommun WHERE streetName = :streetName AND municipalityScb = :municipalityScb');
    $stmt->bindValue(':streetName', $roadname, SQLITE3_TEXT);
    $stmt->bindValue(':municipalityScb', $municipalityScb, SQLITE3_INTEGER);
    
    $roadsStmt = $db->prepare('SELECT DISTINCT streetName FROM pnr96 WHERE postalCode = :postalCode');
    
    $result = $stmt->execute();
    $postalCode = null;
    $postalTown = null;
    while ($row = $result->fetchArray())  {
        $postalCode = intval($row[0]);
        $postalTown = strval($row[1]);
        echo '<hr><p><b>'.htmlspecialchars($postalCode).' '.htmlspecialchars($postalTown)."</b>. Vägar med samma postnummer (i Postnummerkatalogen 1996):</p>\n";
        
        echo "<table>\n";
        $roadsStmt->bindValue(':postalCode', $postalCode, SQLITE3_INTEGER);
        $roadsResult = $roadsStmt->execute();
        while ($roadRow = $roadsResult->fetchArray())  {
            $otherRoad = strval($roadRow[0]);
            echo '<tr><td><small><a href="http://www.openstreetmap.org/search?query='.urlencode($roadname.', '.$muniName).'">[OSM]</a></small></td><td>'.htmlspecialchars($otherRoad)."</td></tr>\n";
        }
        echo "</table>\n";
    }
    if (!$postalCode) {
        echo "<hr><p><em>Hittades ej</em></p>\n";
    }
    
}

?>
<script type="text/javascript">
<!--
function upper() {
    if (document.getElementById) {
        var rn = document.getElementById('roadname');
        rn.value = rn.value.toUpperCase();
    }
    return true;
}
//-->
</script>
</body>
</html>
