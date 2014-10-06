<?php

if(get_magic_quotes_gpc())
	$newCfg = stripslashes($_POST["newConfig"]);
else 
	$newCfg = $_POST["newConfig"];
	
$configFp = fopen($_POST["fileName"], "w+");

fwrite($configFp , $newCfg);

fclose($configFp);

echo "Complete";
?>
                         