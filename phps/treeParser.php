<?php
$treeFp = fopen($_GET["treepath"], "r");
$treeXMLFp = fopen($_GET["output"], "w+");

$xmlPara = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
fwrite($treeXMLFp, $xmlPara);

fwrite($treeXMLFp, "<graph>");

while(!feof($treeFp))
{
	$strLineArray = fgetcsv($treeFp, 512, ";");
	if(count($strLineArray) == 4 || count($strLineArray) == 5)
	{
		$newNode = "<Node";
		$newNode.=" id=\"".$strLineArray[1]."\"";
		$strNodeInfoArray = explode(chr(0x7f), $strLineArray[2]);
		$newNode.=" nodeType=\"".$strNodeInfoArray[0]."\"";
		$newNode.=" name=\"".$strNodeInfoArray[1]."\"";
		//$newNode.=" name=\"".iconv($_GET["encoding"], "utf-8", $strNodeInfoArray[1])."\"";
		$newNode.=" ip=\"".$strNodeInfoArray[2]."\"";
		$strIdxArray = explode(",", $strNodeInfoArray[4]);
		$nodeIdx = $strIdxArray[0];
		$newNode.=" idx=\"".$nodeIdx."\" />";
		$nodeIP = $strNodeInfoArray[2];
		
		fwrite($treeXMLFp, $newNode);
		
		if(strlen($strLineArray[1]) > 3)
		{
			$newEdge = "<Edge";
			$newEdge.=" fromID=\"".substr($strLineArray[1], 0, strlen($strLineArray[1])-3)."\"";
			$newEdge.=" toID=\"".$strLineArray[1]."\"";
			$newEdge.=" toIP=\"".$nodeIP."\"";
		}
		else
		{
			if(count($strLineArray) == 5)
			{
				$newNode = "<Node";
				$newNode.=" id=\"C".$strLineArray[1]."\"";
				$newNode.=" nodeType=\"Cloud\"";
				$newNode.=" name=\"".$strLineArray[3]."\"";
				$newNode.=" ip=\"".$strLineArray[3]."\"";
				$newNode.=" idx=\"\" />";
				fwrite($treeXMLFp, $newNode);
		  
			}
			
			$newEdge = "<Edge";
			$newEdge.=" fromID=\"C".$strLineArray[1]."\"";
			$newEdge.=" toID=\"".$strLineArray[1]."\"";  
		}
    
	
		$logFileName = "/home/tts/online/html/$nodeIP/$nodeIdx.log";
		if(file_exists($logFileName) && $nodeIP != "" && $nodeIdx != "" )
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
		$newEdge.=" bw=\"".$strNodeInfoArray[6]."\"";
		$newEdge.=" ip=\"".$strNodeInfoArray[2]."\"";
		$newEdge.=" idx=\"".$nodeIdx."\" />";
		fwrite($treeXMLFp, $newEdge);
	}
}

fwrite($treeXMLFp, "</graph>");

fclose($treeFp);
fclose($treeXMLFp);

echo "Complete";
?>
                         