<?php

if(get_magic_quotes_gpc())
	$urlAll = stripslashes($_POST["urlAll"]);
else 
	$urlAll = $_POST["urlAll"];

$urlArray = explode("<br>", $urlAll);

#print_r $urlArray;

for($i = 0; $i < count($urlArray); $i ++)
{
	if(substr($urlArray[$i], 0, 2) == "..")
		echo substr($urlArray[$i], 2);
}

?>
                         