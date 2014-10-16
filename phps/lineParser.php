<?php
$lineFp = fopen($_GET["linepath"], "r");
$lineXMLFp = fopen($_GET["output"], "w+");

$xmlPara = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
fwrite($lineXMLFp, $xmlPara);

fwrite($lineXMLFp, "<graph>");

while(!feof($lineFp))
{
	$strLineArray = fgetcsv($lineFp, 512, chr(0x7f));

	$newEdge = "<Edge";
	$newEdge.=" fromIP=\"".$strLineArray[0]."\"";
	$newEdge.=" toIP=\"".$strLineArray[1]."\"";

	$nodeIP = $strLineArray[1];
	$nodeIdx = $strLineArray[3];
	
	$logFileName = "/home/tts/online/html/$nodeIP/$nodeIdx.log";
	if(file_exists($logFileName) && $nodeIP != "" && $nodeIdx != "")
	{
		$logFp = fopen($logFileName, "r");
		$strLineArray2 = fgetcsv($logFp, 512, " ");
		$strLineArray2 = fgetcsv($logFp, 512, " ");
		if(count($strLineArray2) == 5)
		{
			//-------modified--------------------------------------//
			$newEdge.=" rxRate=\"".(string)(((float)$strLineArray2[4]))."\"";
			$newEdge.=" txRate=\"".(string)(((float)$strLineArray2[3]))."\"";
				
		}
		else
		{
			$newEdge.=" rxRate=\"0\"";
			$newEdge.=" txRate=\"0\"";
		}

		fclose($logFp);
	}
	else
	{
		$newEdge.=" rxRate=\"-1\"";
		$newEdge.=" txRate=\"-1\"";
	}
	$newEdge.=" bw=\"".$strLineArray[5]."\"";
	$newEdge.=" port=\"".$strLineArray[2]."\"";
	$newEdge.=" idx=\"".$strLineArray[3]."\" />";
	fwrite($lineXMLFp, $newEdge);

}

fwrite($lineXMLFp, "</graph>");

fclose($lineFp);
fclose($lineXMLFp);

echo "Complete";
?>
                         