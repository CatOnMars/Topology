<?php

if(get_magic_quotes_gpc())
	$locationLog = stripslashes($_POST["location"]);
else 
	$locationLog = $_POST["location"];
	
$locationFp = fopen($_POST["fileName"], "w+");

$xmlPara = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
fwrite($locationFp, $xmlPara);

fwrite($locationFp, "<graph>");
fwrite($locationFp, $locationLog);
fwrite($locationFp, "</graph>");

fclose($locationFp);

echo "Complete";
?>
                         