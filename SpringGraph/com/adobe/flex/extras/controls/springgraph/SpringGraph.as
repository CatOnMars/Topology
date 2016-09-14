/*
 Copyright 2006 Mark E Shepherd

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/


package com.adobe.flex.extras.controls.springgraph {

	import com.adobe.flex.extras.controls.forcelayout.ForceDirectedLayout;
	import com.adobe.flex.extras.controls.forcelayout.Node;
	import com.adobe.flex.extras.controls.springgraph.infoWindow;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextLineMetrics;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.containers.Canvas;
	import mx.containers.TitleWindow;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.DataGrid;
	import mx.controls.HSlider;
	import mx.controls.Image;
	import mx.controls.MenuBar;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.controls.sliderClasses.Slider;
	import mx.core.ClassFactory;
	import mx.core.Container;
	import mx.core.IDataRenderer;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.effects.Effect;
	import mx.effects.Fade;
	import mx.events.EffectEvent;
	import mx.events.MenuEvent;
	import mx.events.SliderEvent;
	import mx.managers.PopUpManager;
	import mx.styles.StyleManager;
	

	//[Event(name="doubleClick", type="flash.events.Event")]



/**

 *  The SpringGraph component displays a set of objects, using 

 *  a force-directed layout algorithm to position the objects.

 *  Behind the objects, the component draws lines connecting

 *  items that are linked.

 * 

 *  <p>The set of objects, and the links between them, is defined

 *  by this component's dataProvider property. For each Item in the dataProvider, 

 *  there is a corresonding itemRenderer, which is any UIComponent that implements

 *  the IDataRenderer interface. You define these via the itemRenderer or viewFactory

 *  properties. Each itemRenderer's 'data' property is a reference to its corresponding Item.</p>

 * 

 *  <p>SpringGraph does its drawing of lines and items inside the

 *  area that you define as the height and width

 *  of this component.</p>

 * 

 * <p>You can control what links look like, in 4 ways:

 * <br>1. do nothing. The edges will draw in a default width and color

 * <br>2. set 'lineColor'. The edges will draw with that color, in a default width.

 * <br>3. use Graph.link() to add a data object to any particular link. If that

 * data object contains a field called 'settings', then the

 * value of 'settings' should be an object with fields 'color', 'thickness', and 'alpha'. For 

 * example:<br><br>

 *     var data: Object = {settings: {alpha: 0.5, color: 0, thickness: 2}};<br>

 *     g.link(fromItem, toItem, data);<br>

 * <br>4. define an EdgeRenderer (see 'edgeRenderer' below)

 * </p>

 *  <p>This component allows the user to click on items and drag them around.

 * </p>

 * 

 *  <p>This component was written by Mark Shepherd of Adobe Flex Builder Engineering.

 *  The force-directed layout algorithm was translated and adapted to ActionScript 3 from 

 *  Java code written by Alexander Shapiro of TouchGraph, Inc. (http://www.touchgraph.com).

 * </p>

 *

 *  @mxml

 *

 *  <p>The <code>&lt;SpringGraph&gt;</code> tag inherits all the tag attributes

 *  of its superclass, and adds the following tag attributes:</p>

 *

 *  <pre>

 *  &lt;mx:SpringGraph

 *    <b>Properties</b>

 *    dataProvider="null"

 *    itemRenderer="null"

 *    lineColor="0xcccccc"

 *    replusionFactor="0.75"

 *  /&gt;

 *  </pre>

 *

 * @author   Mark Shepherd

 */	

 public class SpringGraph extends Canvas {
	 
		//protected var dfltPHPDIR:String = "http://localhost/";
		protected var dfltPHPDIR:String = "../";
		
	 	public var locationFileName:String = "location.xml";
		private var urSave:URLRequest = new URLRequest();
		private var loaderSave:URLLoader;
		private var header:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");

		public var tfRate:TextFormat;
		public var txtFontSize:int = 22;
		public var txtFontColor:int = 0x000000;
		public var forceRefresh:int = 0;
		
				
		public function SpringGraph(): void {

			drawingSurface = new UIComponent();

            this.addEventListener("mouseDown", backgroundMouseDownEvent);

			this.addChild(drawingSurface);
			this.verticalScrollPolicy = "no";
			this.horizontalScrollPolicy = "no";

  			//this.addEventListener("mouseDown", backgroundMouseDownEvent);

			this.addEventListener("mouseUp", dragEnd);
			this.addEventListener("mouseMove", dragContinue);
			this.addEventListener("mouseWheel", wheelHandler);

			this.addEventListener("preinitialize", myPreinitialize);

			this.addEventListener("creationComplete", myCreationComplete);
			drawingSurface.addEventListener("mouseDown", edgeDownEvent);
			drawingSurface.addEventListener("mouseOver", edgeOverEvent);
			drawingSurface.addEventListener("mouseOut", edgeOutEvent);
			
			tfRate = new TextFormat('',txtFontSize);
			tfRate.align = TextFormatAlign.CENTER
			tfRate.color = String(txtFontColor);
		}
		
	
		public static var infoWinMrtg:infoWindow=null;
		public static var infoWinDev:infoWindow=null;
		public static var infoWinVisible:Boolean=false;
		public var infoWinMrtgX:Number=3;
		public var infoWinMrtgY:Number=60;
		public var infoWinDevX:Number=0;
		public var infoWinDevY:Number=0;
		public var infoWinMrtg_height:int=240;
		public var infoWinMrtg_width:int=190;
		public var infoWinDev_height:int=240;
		public var infoWinDev_width:int=0;

		private function infoLocation(event: MouseEvent):void  {
			
			if(infoWinDev.y < 30)
				infoWinDev.y = 30;
				
			if(infoWinMrtg.y < 30)
				infoWinMrtg.y = 30;
			
			if(infoWinDev.x < 3)
				infoWinDev.x = 3;
			
			if(infoWinMrtg.x < 3)
				infoWinMrtg.x = 3;
			
			if(infoWinDev.y > this.height - 30)
				infoWinDev.y = this.height - infoWinDev.height;
			
			if(infoWinMrtg.y > this.height - 30)
				infoWinMrtg.y = this.height - infoWinMrtg.height;
			
			if(infoWinDev.x > this.width - 30)
				infoWinDev.x = this.width - infoWinDev.width;
			
			if(infoWinMrtg.x > this.width - 50)
				infoWinMrtg.x = this.width - infoWinMrtg.width;
			
			event.stopImmediatePropagation();			
		}
		
		public function updateInfoWindowSize():void{
			infoWinMrtg.width = infoWinMrtg_width;
			infoWinMrtg.height = infoWinMrtg_height;
			infoWinDev.width = infoWinDev_width;
			infoWinDev.height = infoWinDev_height;
		}
		
		public function createInfoWindow(parent):void{
			if (infoWinMrtg||infoWinDev)
				return;
			infoWinMrtg=PopUpManager.createPopUp(parent,infoWindow,false) as infoWindow;
			infoWinDev=PopUpManager.createPopUp(parent,infoWindow,false) as infoWindow;
			PopUpManager.bringToFront(infoWinDev);
		//	infoWin.toggle();
			infoWinMrtg.visible=false;
			infoWinDev.visible=false;
			infoWinMrtg.x=infoWinMrtgX;
			infoWinMrtg.y=infoWinMrtgY;
			
			if(infoWinDevX == 0 && infoWinDevY == 0)
			{
				infoWinDev.y=infoWinMrtg.y+infoWinMrtg.height-10;
			}
			else
			{
				infoWinDev.x=infoWinDevX;
				infoWinDev.y=infoWinDevY;
			}
		//	infoWinDev.height=this.height-(infoWinMrtg.y+infoWinMrtg.height);
			var iframe=infoWinMrtg.getChildByName("frame");
			iframe.visible=false;
			
			iframe=infoWinDev.getChildByName("frame");
			iframe.visible=false;
			
			
			infoWinMrtg.otherWin=infoWinDev;
			infoWinDev.otherWin=infoWinMrtg;

			infoWinMrtg.width = infoWinMrtg_width;
			infoWinMrtg.height = infoWinMrtg_height;
			infoWinDev.width = infoWinDev_width;
			infoWinDev.height = infoWinDev_height;
			
			infoWinMrtg.addEventListener("mouseUp", infoLocation);
			infoWinDev.addEventListener("mouseUp", infoLocation);
			infoWinMrtg.addEventListener("mouseMove", infoLocation);
			infoWinDev.addEventListener("mouseMove", infoLocation);
			//infoWinDev.addEventListener(ResizeEvent.RESIZE, onResize);
			
		}
				
		public var mrtgDirPath:String = "../mrtgdata/";
		public var mrtgWebPath:String = "../../../nbad/";

		public var dataGridShown:Boolean = false;
		public var edgeFromNode:GraphNode = null;
		
		protected var edgeUrlFmt:String;
		
		private function transEdgeUrlString(item:Item, url:String, idxStr:String, keyEmpty:Object):String
		{
			var urlString:String = new String(url);

			keyEmpty[0] = false;
			
			while(urlString.search("(mrtgPath)") != -1)
				urlString = urlString.replace("(mrtgPath)", mrtgDirPath);
	
			while(urlString.search("(ip)") != -1)
			{
				urlString = urlString.replace("(ip)", item.data.@ip);
				if(String(item.data.@ip).length == 0)
					keyEmpty[0] = true;
			}

			while(urlString.search("(idx)") != -1)
			{
				urlString = urlString.replace("(idx)", idxStr);
				if(String(idxStr).length == 0)
					keyEmpty[0] = true;
			}

			while(urlString.search("(id)") != -1)
			{
				urlString = urlString.replace("(id)", item.data.@id);
				if(String(item.data.@id).length == 0)
					keyEmpty[0] = true;
			}

			while(urlString.search("(nodeType)") != -1)
				urlString = urlString.replace("(nodeType)", item.data.@nodeType);

			while(urlString.search("(name)") != -1)
				urlString = urlString.replace("(name)", item.data.@name);
			
			return urlString;
		}
		
		public function edgeOverEvent(event: MouseEvent):void  {
			var x: int = event.localX;
			var y: int = event.localY;
			
			var edges: Array = _dataProvider.getEdges();
			var rxRateTmp: Number;
			var txRateTmp: Number;
			var minDistance:int = 20;
			var toNodeTmp: GraphNode;
			var isFound:Boolean = false;
			var toItem:Item = null;			
			
			for each (var edge: GraphEdge in edges) {
				var fromNode: GraphNode = GraphNode(edge.getFrom());
				var toNode: GraphNode = GraphNode(edge.getTo());
				var fromX: int = fromNode.view.x + (fromNode.view.width / 2);
				var fromY: int = fromNode.view.y + (fromNode.view.height / 2);
				var toX: int = toNode.view.x + (toNode.view.width / 2);
				var toY: int = toNode.view.y + (toNode.view.height / 2);
				var a: int = toY - fromY;
				var b: int = fromX - toX;
				var c: int = (toX - fromX) * fromY - (toY - fromY) * fromX;
				var calcChild: Number = a*x + b*y + c;
				if(calcChild < 0) calcChild = - calcChild;
				var calcMother: Number = Math.sqrt(a*a + b*b);
				var distance: Number = calcChild / calcMother;
				var keyEmpty:Object = new Object();
				var urlString:String;

				/*check X range*/
				var checkX_left:int;
				var checkX_right:int;
				if(fromX >= toX)
				{
					checkX_left = toX;
					checkX_right = fromX;
				}
				else
				{
					checkX_left = fromX;
					checkX_right = toX;
				}
				if(checkX_right - checkX_left > 15) /*X of 2 points should be far enough to compare*/
					if(x < checkX_left || x > checkX_right) /* X no resonable */
						continue;
				/*check Y range*/
				var checkY_up:int;
				var checkY_down:int;
				if(fromY >= toY)
				{
					checkY_up = fromY;
					checkY_down = toY;
				}
				else
				{
					checkY_up = toY;
					checkY_down = fromY;
				}
				if(checkY_up - checkY_down > 15) /*Y of 2 points should be far enough to compare*/
					if(y < checkY_down || y > checkY_up) /* Y no resonable */
						continue;
				
				if(distance < minDistance)
				{
					var linkData: Object = _graph.getLinkData(fromNode.item, toNode.item);
					var rxRate: Number;
					var txRate: Number;
					
					if(linkData.hasOwnProperty("rxRate"))
						rxRate = linkData.rxRate;
					else
						rxRate = -1;
					
					if(linkData.hasOwnProperty("txRate"))
						txRate = linkData.txRate;
					else
						txRate = -1;
					
					if(rxRate == -1 || txRate == -1) //do not display or pop out a datagrid with -1 rate
						continue;
					
					if(linkData.hasOwnProperty("toNodeID"))
					{
						if(fromNode.item.id == linkData.toNodeID)
							toItem = fromNode.item;
						
						if(toNode.item.id == linkData.toNodeID)
							toItem = toNode.item;
					}
					
					rxRateTmp = rxRate;
					txRateTmp = txRate;
					toNodeTmp = toNode;
					minDistance = distance;
					isFound = true;
				}
			}
			
			if(isFound == true)
			{
				var rxRateStr: String;
				var txRateStr: String;
				var idxStr:String;
			
			
				rxRateStr = linkData.rxRateStr;
				txRateStr = linkData.txRateStr;
				
				
				var dataXMLList:XMLList = 
					<>
					<fv>
						<f>TX Rate</f>
						<v>{rxRateStr}</v>
					</fv>
					<fv>
						<f>RX Rate</f>
						<v>{txRateStr}</v>
					</fv>
					</>
				
				dataGrid.rowCount = dataXMLList.length();
				var cols:Array = new Array();
				var gridColumn:DataGridColumn = new DataGridColumn();
				gridColumn.dataField = "f";
				gridColumn.headerText = "Field";
				cols.push(gridColumn);
				var gridColumn2:DataGridColumn = new DataGridColumn();
				gridColumn2.dataField = "v";
				gridColumn2.headerText = "Value";
				cols.push(gridColumn2);
				dataGrid.columns=cols;
				dataGrid.dataProvider = dataXMLList;
				if((dataGrid.x = event.localX - dataGrid.width - 50) < 0)
					dataGrid.x = event.localX + 50;
				
				if((dataGrid.y = event.localY - dataGrid.height) < 0)
					dataGrid.y = event.localY + dataGrid.height;
				
				this.addChild(dataGrid);
				
				dataGridShown = true;
				edgeFromNode = toNodeTmp;
				
				if(linkData.hasOwnProperty("idx"))
					idxStr = linkData.idx;
				else
					idxStr = "";
				
				((myItemView)(edgeFromNode.view)).edgeUrl = "none";
				
				if(toItem != null)
				{
					urlString = transEdgeUrlString(toItem, edgeUrlFmt, idxStr, keyEmpty);
					((myItemView)(edgeFromNode.view)).edgeUrl = urlString;
					//Alert.show("edgeUrl:"+((myItemView)(edgeFromNode.view)).edgeUrl);
				}
				
			}
		}
		
		public function edgeOutEvent(event: MouseEvent):void  {
			
			if(dataGridShown == true)
			{
				
				this.removeChild(dataGrid);
				dataGridShown = false;
				edgeFromNode = null;
			}
		}
		
		public function edgeDownEvent(event: MouseEvent):void  {
			var now: int = getTimer();
			if((now - lastMouseDownTime) < 300) {
				// it's a double-click
				//Alert.show((edgeFromNode == null).toString());
				
				if(edgeFromNode != null) {
					//trace("double click to " + node.item.data.@idx + " " + node.item.data.@ip);
					//Alert.show(((myItemView)(edgeFromNode.view)).edgeUrl);
					if(((myItemView)(edgeFromNode.view)).edgeUrl != "none")
						navigateToURL(new URLRequest(((myItemView)(edgeFromNode.view)).edgeUrl), "_blank");
				}
				return;
			}
			lastMouseDownTime = now;
			event.stopImmediatePropagation();
		}
		
		public var wheelScale:Number = 80;
		public var wheelLocation:Number = 80;
		public var wheelScaleLog:Number = 80;
		public var wheelLocationLog:Number = 80;
		
		private function wheelHandler(event: MouseEvent):void  {
			var scaleDelta:Number;
			var locationDelta:Number;
							 
			
			if(_viewFactory != null)
			{
				if(wheelScale != 0)
				{
					scaleDelta = event.delta /wheelScale;
					if((myViewFactory)(_viewFactory).itemScale + scaleDelta >= 0)
					{
						(myViewFactory)(_viewFactory).itemScale += scaleDelta;
						
						scaleLog = String((myViewFactory)(_viewFactory).itemScale);
					
						if(_dataProvider != null)
							_dataProvider.forAllNodes(new Scaler(scaleDelta));
						
					
					}
				}
				
				if(wheelLocation != 0)
				{
					locationDelta = event.delta/wheelLocation;
					if(_dataProvider != null)
						_dataProvider.forAllNodes(new LocationChanger(locationDelta, this.width/2, this.height/2));
				}
			}
			
			refresh();
		}
			
		private var _menuBarXML:XML;
		
		[Embed(source='rateHelp.png')]
		private var RateHelpPng:Class;
		var rateHelpImg:Image = new Image();
		
		[Embed(source='atkHelp.png')]
		private var AtkHelpPng:Class;
		var atkHelpImg:Image = new Image();
		
		[Embed(source='statusHelp.png')]
		private var StatusHelpPng:Class;
		var statusHelpImg:Image = new Image();
		
		public function setUI(menuBarXML:XML, dfltIsManual:Boolean, dfltShowRate:Boolean, dfltShowAttack:Boolean, 
							  dfltShowStatus:Boolean, dfltAlpha:Number, dfltFontSize:int, dfltRateLine:int, canSave:Boolean): void{
			
			if(menuBar == null)
			{
				menuBar = new MenuBar();
				menuBar.showRoot = false;
				menuBar.labelField = "@label";
				menuBar.setStyle("menuStyleName", "myStyle");
				menuBar.addEventListener("itemClick", menuClickHandler);
				menuBar.x = 0;
				menuBar.y = 0;

				this.addChild(menuBar);
				
				_menuBarXML = menuBarXML;
				menuBar.dataProvider = _menuBarXML;
				addManualButton(dfltIsManual);
				addSaveButton(canSave);
				addSliders(dfltAlpha, dfltFontSize, dfltRateLine);
				
				rateHelpImg.source = RateHelpPng;
				rateHelpImg.x = 5;
				rateHelpImg.y = 80;
				if(dfltShowRate == true)
					this.addChild(rateHelpImg);
				
				atkHelpImg.source = AtkHelpPng;
				atkHelpImg.x = 5;
				atkHelpImg.y = 30;
				if(dfltShowAttack == true)
					this.addChild(atkHelpImg);
				
				statusHelpImg.source = StatusHelpPng;
				statusHelpImg.x = 70;
				statusHelpImg.y = 30;
				statusHelpImg.alpha = 0.8;
				if(dfltShowStatus == true)
					this.addChild(statusHelpImg);
			}
			
		}
		
		public function updateUILocation(saveX:int, saveY:int, manualX:int, manualY:int):void
		{
			if(saveButton != null)
			{
				saveButton.x = saveX;
				saveButton.y = saveY;
			}
			else
				trace("saveButton null");
			
			if(manualButton != null)
			{
				manualButton.x = manualX;
				manualButton.y = manualY;
			}
			else
				trace("manualButton null");
		}
		
		protected var showBGLog:String = "true";
		protected var showRateLog:String = "true";
		protected var showRateInfoLog:String = "true";		
		protected var showAttackLog:String = "true";
		protected var showStatusLog:String = "true";
		protected var distanceLog:String = "4";
		protected var nodeLog:String = "50";
		protected var txtLog:String = "ip";
		protected var hideVlanLog:String = "false";
		protected var hideGroupLog:String = "false";
		protected var hideLineLog:String = "false";
		protected var manualLog:String = "false";
		protected var alphaLog:String = "1";
		protected var fontSizeLog:String = "1";
		protected var rateLineLog:String = "1";
		protected var scaleLog:String = "1";
		protected var currentIDLog:String = "";
		
		protected var sndIdx:Object={Bad:"",Alarm:"",Victim:""};
		
		private function menuClickHandler(event:MenuEvent):void
		{
			var sndGroup:String=event.item.@groupName;
		//	Alert.show(event.item.@label);
			if (sndGroup=="Alarm"){
				sndIdx["Alarm"]=event.item.@label;
				return;
			}
			else if(sndGroup=="Bad"){
				sndIdx["Bad"]=event.item.@label;
				return;
			}
			else if(sndGroup=="Victim"){
				sndIdx["Victim"]=event.item.@label;
				return;
			}
			
			var dataStrArray = event.item.@data.split('_');
			if(dataStrArray[0] == "network")
			{
				updateCurrentItem(dataStrArray[1]);
				currentIDLog = dataStrArray[1];
			}
			else if(dataStrArray[0] == "showBG")
			{
				var c: Array = this.getChildren();
				var itemView: Object = c[0];
				if(event.item.@toggled == "true")
				{
					if(itemView!=null)
					{
						itemView.visible = true;
						wheelLocation = 0;
					}
				}
				else
				{
					if(itemView!=null)
					{
						itemView.visible = false;
						wheelLocation = wheelLocationLog;
					}
				}
				
				
				showBGLog = event.item.@toggled;
			}
			else if(dataStrArray[0] == "showRate")
			{
				var showRate:Boolean;
				if(event.item.@toggled == "true")
				{
					showRate = true;
					this.addChild(rateHelpImg);
				}
				else
				{
					showRate = false;
					this.removeChild(rateHelpImg);
				}
				//menuBarHdl.showRate(showRate);
				if(_edgeRenderer != null)
				{
					(myEdgeRenderer)(_edgeRenderer).showRate = showRate;
					drawEdges();
				}
				else
					trace("edgeRender = null");
				
				showRateLog = event.item.@toggled;
			}
			else if(dataStrArray[0] == "showRateInfo")
			{
				var showRateInfo:Boolean;
				if(event.item.@toggled == "true")
				{
					showRateInfo = true;
				}
				else
				{
					showRateInfo = false;
				}
				//menuBarHdl.showRate(showRate);
				showRateInfoLog = event.item.@toggled;
				
				if(_edgeRenderer != null)
				{
					(myEdgeRenderer)(_edgeRenderer).showRateInfo = showRateInfo;
					drawEdges();
				}
				else
					trace("edgeRender = null");
				

			}
			else if(dataStrArray[0] == "showAttack")
			{
				
				var showAttack:Boolean;
				if(event.item.@toggled == "true")
				{
					showAttack = true;
					this.addChild(atkHelpImg);
				}
				else
				{
					showAttack = false;
					this.removeChild(atkHelpImg);
				}
				//menuBarHdl.showAttack(showAttack);
				
				if(_viewFactory != null)
				{
					(myViewFactory)(_viewFactory).showAttack = showAttack;
					if(_dataProvider != null)
						_dataProvider.reDrawAttackNodes();
					
					rebuild();
				}
				
				if(_edgeRenderer != null)
				{
					(myEdgeRenderer)(_edgeRenderer).showAttack = showAttack;
					drawEdges();
				}
				
				//setDataProvider(_graph);
				//reDrawItems();	
				showAttackLog = event.item.@toggled;
			}
			else if(dataStrArray[0] == "showStatus")
			{
				var showStatus:Boolean;
				if(event.item.@toggled == "true")
				{
					showStatus = true;
					this.addChild(statusHelpImg);
				}
				else
				{
					showStatus = false;
					this.removeChild(statusHelpImg);
				}
				
				if(_viewFactory != null)
				{
					(myViewFactory)(_viewFactory).showStatus = showStatus;
					if(_dataProvider != null)
					{			
						_dataProvider.clearStatus();
						_dataProvider.reDrawStatus();
					}
					
					rebuild();
				}
				showStatusLog = event.item.@toggled;
			}
			else if(event.item.@groupName == "devFontColor")
			{
				if(_viewFactory != null)
					(myViewFactory)(_viewFactory).txtFontColor = event.item.@data;
				
				forceRefresh = 1;
			}
			else if(event.item.@groupName == "rateFontColor")
			{
				this.txtFontColor = event.item.@data;
				if(tfRate != null)
				{
					tfRate.color = String(event.item.@data);
				}
				
				forceRefresh = 1;
			}
			else if(dataStrArray[0] == "distance")
			{
				doRecordLocation();
				updateDistance(Number(dataStrArray[1]));
				distanceLog = dataStrArray[1];
			}
			else if(dataStrArray[0] == "node")
			{
				doRecordLocation();
				updateMaxNode(Number(dataStrArray[1]));
				nodeLog = dataStrArray[1];
			}
			else if(dataStrArray[0] == "txt")
			{
				if(_viewFactory != null)
					(myViewFactory)(_viewFactory).txtInfo = dataStrArray[1];
				
				//setDataProvider(_graph);
				//reDrawItems();
				//updateCurrentItem(_currentItem.id);
				setItemTxt();
				txtLog = dataStrArray[1];
			}
			else if(dataStrArray[0] == "hideVlan")
			{
				if(event.item.@toggled == "true")
				{
					setHideVlan(true);
				}
				else
				{
					setHideVlan(false);
				}
				hideVlanLog = event.item.@toggled;
			}
			else if(dataStrArray[0] == "hideGroup")
			{
				if(event.item.@toggled == "true")
				{
					setHideGroup(true);
				}
				else
				{
					setHideGroup(false);
				}
				hideGroupLog = event.item.@toggled;
			}
			else if(dataStrArray[0] == "hideLine")
			{
				if(event.item.@toggled == "true")
				{
					setHideLine(true);
				}
				else
				{
					setHideLine(false);
				}
				hideLineLog = event.item.@toggled;
			}
			
			
		}
		
		/*overwrited by roamer*/
		protected function setItemTxt():void
		{
			
		}
		
		/*overwrited by roamer*/
		protected function setHideVlan(hideVlan:Boolean):void
		{
			
		}
		
		/*overwrited by roamer*/
		protected function setHideGroup(hideGroup:Boolean):void
		{
			
		}
		
		/*overwrited by roamer*/
		protected function setHideLine(hideLine:Boolean):void
		{
			
		}
		
		public function clearAttack():void
		{
			if(_viewFactory != null)
			{
				if(_dataProvider != null)
					_dataProvider.clearAttackNodes();
				
				rebuild();
			}
		}
		
		public function reDrawAttack():void
		{
			if(_viewFactory != null)
			{
				if(_dataProvider != null)
					_dataProvider.reDrawAttackNodes();
				
				rebuild();
			}
			
			if(_edgeRenderer != null)
			{
				drawEdges();
			}
		}
		
		public function clearStatus():void
		{
			if(_viewFactory != null)
			{
				if(_dataProvider != null)
					_dataProvider.clearStatus();
				
				rebuild();
			}
		}
		
		public function reDrawStatus():void
		{
			if(_viewFactory != null)
			{
				
				if(_dataProvider != null)
					_dataProvider.reDrawStatus();
				
				rebuild();
				
			}
			
			if(_edgeRenderer != null)
			{
				drawEdges();
			}
		}
		
		/*to be overrided by roamer*/
		protected function updateCurrentItem(itemID:String):void 
		{			
		}
		
		/*to be overrided by roamer*/
		protected function updateDistance(distance:int):void 
		{			
		}
		
		/*to be overrided by roamer*/
		protected function updateMaxNode(maxNode:int):void 
		{			
		}
		
		/*to be overrided by roamer*/
		protected function reDrawItems():void 
		{			
		}
		
		private var manualButton:Button;
		private var isManual:Boolean = true;
		
		public function addManualButton(dfltIsManual:Boolean): void{
			manualButton = new Button();
			if(dfltIsManual == true)
				manualButton.label = "Manual";
			else
				manualButton.label = "Auto";
			isManual = dfltIsManual;
			manualButton.x = menuBar.x + menuBar.width + 5;
			//manualButton.x = 200;
			manualButton.y = 0;
			manualButton.addEventListener(MouseEvent.CLICK, changeManualAuto);
			this.addChild(manualButton);
		}
		
		private function changeManualAuto(event:Event):void 
		{			
			if(isManual == true)
			{
				manualButton.label = "Auto";
				isManual = false;
				manualLog = "false";
			}
			else
			{
				manualButton.label = "Manual";
				isManual = true;
				manualLog = "true";
			}
		}
		
		private var saveButton:Button;
		
		public function addSaveButton(canSave:Boolean): void{
			saveButton = new Button();
			saveButton.label = "Save";
			saveButton.x = manualButton.x + manualButton.width + 5;
		//	saveButton.x = 300;
			saveButton.addEventListener(MouseEvent.CLICK, doSave);
			if(canSave == false)
				saveButton.enabled = false;
			this.addChild(saveButton);
		}
		
		public var locationLog: String;
		
		public function doRecordLocation():void
		{
			var nodes: Array;
			var nodeItem: Item;
						
			if(_dataProvider != null)
			{
				nodes = _dataProvider.getAllNodes();
				
				locationLog = "<?xml version=\"1.0\" encoding=\"utf-8\" ?><graph>";
				
				for each (var node: Node in nodes) {
					nodeItem = fullGraph.find((GraphNode)(node).item.id);
					if(nodeItem != null)
					{
						nodeItem.X = (GraphNode)(node).view.x;
						nodeItem.Y = (GraphNode)(node).view.y;
						
						locationLog = locationLog + "<location id=\"" + nodeItem.id + "\" x=\"" + nodeItem.X + "\" y=\"" + nodeItem.Y + "\"/>";
					}
				}
				
				locationLog = locationLog +  "</graph>";
			}
		}
		
		public function doSaveLocationCache():void
		{
			var nodes: Object;
			var locationLog: String;
			
			
			if(_graph != null)
			{
				nodes = fullGraph.nodes;
				
				locationLog = "";
				for each (var node: Item in nodes) {
					locationLog = locationLog + "<location id=\"" + node.id + "\" x=\"" + node.X + "\" y=\"" + node.Y + "\"/>";
				}
				
				locationLog = locationLog + "<location id=\"" + "infoWinMrtg" + "\" x=\"" + infoWinMrtg.x + "\" y=\"" + infoWinMrtg.y + "\"/>";
				locationLog = locationLog + "<location id=\"" + "infoWinDev" + "\" x=\"" + infoWinDev.x + "\" y=\"" + infoWinDev.y + "\"/>";
				
				
				urSave.url = dfltPHPDIR + "locationCacheSave.php";	
				urSave.method = URLRequestMethod.POST;
				urSave.requestHeaders.push(header);
				urSave.data = new URLVariables("fileName="+locationFileName+"&location="+locationLog+"&time="+Number(new Date().getTime()));
				loaderSave = new URLLoader();
				loaderSave.load(urSave);
			}
		}
		
		
	
		public function doSaveLocation():void
		{
			var nodes: Object;
			var locationLog: String;			
			
			if(_graph != null)
			{
				nodes = fullGraph.nodes;
				
				locationLog = "";
				for each (var node: Item in nodes) {
					locationLog = locationLog + "<location id=\"" + node.id + "\" x=\"" + node.X + "\" y=\"" + node.Y + "\"/>";
				}
				
				locationLog = locationLog + "<location id=\"" + "infoWinMrtg" + "\" x=\"" + infoWinMrtg.x + "\" y=\"" + infoWinMrtg.y + "\"/>";
				locationLog = locationLog + "<location id=\"" + "infoWinDev" + "\" x=\"" + infoWinDev.x + "\" y=\"" + infoWinDev.y + "\"/>";
				
				
				urSave.url = dfltPHPDIR + "locationSave.php";	
				urSave.method = URLRequestMethod.POST;
				urSave.requestHeaders.push(header);
				urSave.data = new URLVariables("fileName="+locationFileName+"&location="+locationLog+"&time="+Number(new Date().getTime()));
				loaderSave = new URLLoader();
				loaderSave.load(urSave);
			}
		}
		
		private function doSave(event:Event):void
		{
			doRecordLocation();
			doSaveLocation();
			
			/*call roamer function to save config*/
			doSaveConfig();
		}
		
		/*to be overrided by roamer*/
		protected function doSaveConfig():void
		{
			
		}
		
		
		
		private var alphaSlider:HSlider;
		private var fontSizeSlider:HSlider;
		private var rateThickSlider:HSlider;
				
		public function addSliders(dfltAlpha:Number, dfltFontSize:int, dfltRateLine:int): void{
			alphaSlider = new HSlider();
			alphaSlider.x = saveButton.x + saveButton.width + 5;
			alphaSlider.x = 298+70;
			alphaSlider.y = 0;
			alphaSlider.minimum = 0.0;
			alphaSlider.maximum = 1.0;
			alphaSlider.addEventListener(SliderEvent.CHANGE, changeAlphaSlider);
			alphaSlider.addEventListener("mouseDown", sliderMouseDown);
			alphaSlider.width = 60;
			alphaSlider.liveDragging = true;
			var txtArray:Array = new Array();
			txtArray.push("");
			txtArray.push("alpha");
			txtArray.push("");
			alphaSlider.labels = txtArray;
			
			this.addChild(alphaSlider);
			
			alphaSlider.value = dfltAlpha;
			
			fontSizeSlider = new HSlider();
			fontSizeSlider.x = alphaSlider.x + alphaSlider.width + 5;
			fontSizeSlider.x = 358+70;
			fontSizeSlider.y = 0;
			fontSizeSlider.minimum = 6;
			fontSizeSlider.maximum = 127;
			fontSizeSlider.addEventListener(SliderEvent.CHANGE, changeFontSlider);
			fontSizeSlider.addEventListener("mouseDown", sliderMouseDown);
			fontSizeSlider.width = 60;
			fontSizeSlider.liveDragging = true;
			txtArray = new Array();
			txtArray.push("");
			txtArray.push("font size");
			txtArray.push("");
			fontSizeSlider.labels = txtArray;
			
			this.addChild(fontSizeSlider);
			
			fontSizeSlider.value = dfltFontSize;
			
			rateThickSlider = new HSlider();
			rateThickSlider.x = fontSizeSlider.x + fontSizeSlider.width + 5;
			rateThickSlider.x = 418+70;
			rateThickSlider.y = 0;
			rateThickSlider.minimum = 1;
			rateThickSlider.maximum = 8;
			rateThickSlider.addEventListener(SliderEvent.CHANGE, changeRateLineSlider);
			rateThickSlider.addEventListener("mouseDown", sliderMouseDown);
			rateThickSlider.width = 60;
			rateThickSlider.liveDragging = true;
			txtArray = new Array();
			txtArray.push("");
			txtArray.push("rate line");
			txtArray.push("");
			rateThickSlider.labels = txtArray;
			
			this.addChild(rateThickSlider);
			
			rateThickSlider.value = dfltRateLine;
		}
		
		private function changeAlphaSlider(event:SliderEvent):void 
		{	
			event.stopImmediatePropagation();
			if(_dataProvider != null)
				_dataProvider.forAllNodes(new AlphaChanger(event.value));
			
			if(_viewFactory != null)
				(myViewFactory)(_viewFactory).viewAlpha = event.value;
			
			alphaLog = event.value.toString();
			refresh();
		}
		
		private function changeFontSlider(event:SliderEvent):void 
		{	
			event.stopImmediatePropagation();
			if(_dataProvider != null)
				_dataProvider.forAllNodes(new FontSizeChanger(event.value));
			
			if(_viewFactory != null)
				(myViewFactory)(_viewFactory).txtFontSize = event.value;
			
			fontSizeLog = event.value.toString();
			refresh();
		}
		
		private function changeRateLineSlider(event:SliderEvent):void 
		{	
			event.stopImmediatePropagation();
			
			if(_edgeRenderer != null)
				(myEdgeRenderer)(_edgeRenderer).rateThickness = event.value;
			
			rateLineLog = event.value.toString();
			drawEdges();
		}
				
		private function sliderMouseDown(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
		}
		

	    /** @private */

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
   			super.updateDisplayList(unscaledWidth, unscaledHeight);

			if((_dataProvider != null) && _dataProvider.layoutChanged) {
				drawEdges();
				_dataProvider.layoutChanged = false;
			}
		}

		

	    /** @private */

		protected function drawEdges(): void {
			drawingSurface.graphics.clear();
			
			if(_dataProvider != null)
			{
				var edges: Array = _dataProvider.getEdges();
				
				for each (var edge: GraphEdge in edges) {
					var fromNode: GraphNode = GraphNode(edge.getFrom());
					var toNode: GraphNode = GraphNode(edge.getTo());
					var color: int = ((fromNode.item == distinguishedItem) || (toNode.item == distinguishedItem))
						? distinguishedLineColor : _lineColor;
					drawEdge(fromNode.view, toNode.view, color);
				}
			}
		}


		private function drawEdge(f: UIComponent, t: UIComponent, color: int): void {
			var fromX: int = f.x + (f.width / 2);
			var fromY: int = f.y + (f.height / 2);
			var toX: int = t.x + (t.width / 2);
			var toY: int = t.y + (t.height / 2);
			var fromItem: Item = (f as IDataRenderer).data as Item;
			var toItem: Item = (t as IDataRenderer).data as Item;
			var linkData: Object;
			var tmp: Object;
			
			if((_edgeRenderer != null) && _edgeRenderer.draw(drawingSurface.graphics, f, t, fromX, fromY, toX, toY, _graph))
			{
				/*add rate text*/

				linkData = _graph.getLinkData(fromItem, toItem);
				
				if(linkData != null)
				{
					if(toItem.id < fromItem.id)
					{
						tmp = f;
						f = t;
						t = (UIComponent)(tmp);
						tmp = fromItem;
						fromItem = toItem;
						toItem = (Item)(tmp);
						tmp = fromX;
						fromX = toX;
						toX = (int)(tmp);
						tmp = fromY;
						fromY = toY;
						toY = (int)(tmp);
					}
					
					if(! ((myEdgeRenderer)(_edgeRenderer).showRate == true && showRateInfoLog == "true"))
					{
						if ((myItemView)(t).txRateTxt.hasOwnProperty(fromItem.id))
							(myItemView)(t).txRateTxt[fromItem.id].visible = false;
						
						if ((myItemView)(t).rxRateTxt.hasOwnProperty(fromItem.id))
							(myItemView)(t).rxRateTxt[fromItem.id].visible = false;
						
						return;
					}
						
					
					if(linkData.txRate > 0)
					{
						if(! (myItemView)(t).rxRateTxt.hasOwnProperty(fromItem.id))
						{
							var rxRateTxt:TextField = new TextField();
							
							rxRateTxt.text = "test";
							rxRateTxt.setTextFormat(tfRate);
							rxRateTxt.defaultTextFormat = tfRate;
							rxRateTxt.selectable = false;
							rxRateTxt.autoSize = TextFieldAutoSize.LEFT;
							rxRateTxt.border = true;		
							rxRateTxt.visible = false;
							
							(myItemView)(t).rxRateTxt[fromItem.id] = rxRateTxt;
							(myItemView)(t).addChild(rxRateTxt);
						}
						
						(myItemView)(t).rxRateTxt[fromItem.id].text = linkData.txPercent.toPrecision(3) + " %\n" + "RX:"+linkData.txRateStr;
						(myItemView)(t).rxRateTxt[fromItem.id].x = ((fromX - toX) / 8 * 3) / t.scaleX - (myItemView)(t).rxRateTxt[fromItem.id].width/2 * t.scaleX;
						(myItemView)(t).rxRateTxt[fromItem.id].y = ((fromY - toY) / 8 * 3) / t.scaleY - (myItemView)(t).rxRateTxt[fromItem.id].height/2 * t.scaleY;
						(myItemView)(t).rxRateTxt[fromItem.id].visible = true;
					}
					
					if(linkData.rxRate > 0)
					{
						if(! (myItemView)(t).txRateTxt.hasOwnProperty(fromItem.id))
						{
							var txRateTxt:TextField = new TextField();
							
							txRateTxt.text = "test";
							txRateTxt.setTextFormat(tfRate);
							txRateTxt.defaultTextFormat = tfRate;
							txRateTxt.selectable = false;
							txRateTxt.autoSize = TextFieldAutoSize.LEFT;
							txRateTxt.border = true;		
							txRateTxt.visible = false;
							
							(myItemView)(t).txRateTxt[fromItem.id] = txRateTxt;
							(myItemView)(t).addChild(txRateTxt);
						}
						
						(myItemView)(t).txRateTxt[fromItem.id].text = linkData.rxPercent.toPrecision(3) + " %\n" + "TX:"+linkData.rxRateStr;
						(myItemView)(t).txRateTxt[fromItem.id].x = ((fromX - toX) / 8 * 5) / t.scaleX - (myItemView)(t).txRateTxt[fromItem.id].width/2 * t.scaleX;
						(myItemView)(t).txRateTxt[fromItem.id].y = ((fromY - toY) / 8 * 5) / t.scaleY - (myItemView)(t).txRateTxt[fromItem.id].height/2 * t.scaleY;
						(myItemView)(t).txRateTxt[fromItem.id].visible = true;
					}
			
				}
				
				
				/*
				if(toItem.id > fromItem.id)
				{
					if(toItem.rxRate > 0 && toItem.txRate > 0 && (myEdgeRenderer)(_edgeRenderer).showRate == true && showRateInfoLog == "true")
					{
						(myItemView)(t).rxRateTxt.text = toItem.txPercent.toPrecision(3) + " %\n" + "RX:"+toItem.txRateStr;
						(myItemView)(t).rxRateTxt.x = ((fromX - toX) / 4) / t.scaleX - (myItemView)(t).rxRateTxt.width/2 * t.scaleX;
						(myItemView)(t).rxRateTxt.y = ((fromY - toY) / 4) / t.scaleY - (myItemView)(t).rxRateTxt.height/2 * t.scaleX;
						(myItemView)(t).rxRateTxt.visible = true;
						
						(myItemView)(t).txRateTxt.text = toItem.rxPercent.toPrecision(3) + " %\n" + "TX:"+toItem.rxRateStr;
						(myItemView)(t).txRateTxt.x = ((fromX - toX) / 4 * 3) / t.scaleX - (myItemView)(t).txRateTxt.width/2 * t.scaleX;
						(myItemView)(t).txRateTxt.y = ((fromY - toY) / 4 * 3) / t.scaleY - (myItemView)(t).txRateTxt.height/2 * t.scaleY;
						(myItemView)(t).txRateTxt.visible = true;
					}
					else
					{
						(myItemView)(t).rxRateTxt.visible = false;
						(myItemView)(t).txRateTxt.visible = false;
					}
				}
				else
				{
					if(fromItem.rxRate > 0 && fromItem.txRate > 0 && (myEdgeRenderer)(_edgeRenderer).showRate == true && showRateInfoLog == "true")
					{
						(myItemView)(f).rxRateTxt.text = fromItem.txPercent.toPrecision(3) + " %\n" + "RX:"+fromItem.txRateStr;
						(myItemView)(f).rxRateTxt.x = ((toX - fromX) / 4) / f.scaleX - (myItemView)(f).rxRateTxt.width/2 * f.scaleX;
						(myItemView)(f).rxRateTxt.y = ((toY - fromY) / 4) / f.scaleY - (myItemView)(f).rxRateTxt.height/2 * f.scaleY;
						(myItemView)(f).rxRateTxt.visible = true;
						
						(myItemView)(f).txRateTxt.text = fromItem.rxPercent.toPrecision(3) + " %\n" + "TX:"+fromItem.rxRateStr;
						(myItemView)(f).txRateTxt.x = ((toX - fromX) / 4 * 3) / f.scaleX - (myItemView)(f).txRateTxt.width/2 * f.scaleX;
						(myItemView)(f).txRateTxt.y = ((toY - fromY) / 4 * 3) / f.scaleY - (myItemView)(f).txRateTxt.height/2 * f.scaleY;
						(myItemView)(f).txRateTxt.visible = true;
					}
					else 
					{
						(myItemView)(f).rxRateTxt.visible = false;
						(myItemView)(f).txRateTxt.visible = false;
					}
				}
				*/

				return;
			}

			var linkData: Object = _graph.getLinkData(fromItem, toItem);
			var alpha: Number = 1.0;
			var thickness: int = 1;

			if((linkData != null) && (linkData.hasOwnProperty("settings"))) {
				var settings: Object = linkData.settings;
				alpha = settings.alpha;
				thickness = settings.thickness;
				color = settings.color;
			}

		
			drawingSurface.graphics.lineStyle(thickness,color,alpha);
			drawingSurface.graphics.beginFill(0);
			drawingSurface.graphics.moveTo(fromX, fromY);
			drawingSurface.graphics.lineTo(toX, toY);
			drawingSurface.graphics.endFill();
		}

 		

 		private function myPreinitialize(event: Object): void {

			var dp: GraphDataProvider = new GraphDataProvider(this);

			_dataProvider = dp;

			forceDirectedLayout = new ForceDirectedLayout(dp);

			refresh();

 		}

 		

 		private function myCreationComplete(event: Object): void {

 			creationIsComplete = true;

 			if(pendingDataProvider != null) {

 				doSetDataProvider(pendingDataProvider);

 				pendingDataProvider = null;

 			}

 			rebuild();

 		}

 		

	    /** @private */

 		public function removeComponent(component: UIComponent): void {
 			//Object(component).removeYourself();

 			if(removeItemEffect != null) {

 				removeItemEffect.addEventListener(EffectEvent.EFFECT_END, removeEffectDone);

	 			removeItemEffect.createInstance(component).startEffect();

	 		} else {

	 			component.parent.removeChild(component);

	 		}

  		}

  		

  		private function removeEffectDone(event: EffectEvent): void {
  			var component: UIComponent = event.effectInstance.target as UIComponent;

  			if(component.parent != null)

				component.parent.removeChild(component);

  		}

		

		/** An effect that is applied to all itemRenderer instances when they

		 * are removed from the spring graph. */ 

		public var removeItemEffect: Effect;

		

		/** An effect that applied to all itemRenderer instances when they

		 * are add to the spring graph. */ 

		public var addItemEffect: Effect;



		/**The XML element and attribute names to use when parsing an XML dataProvider.

		   The array must have 4 elements:

		   <ul>

		   <li> the element name that defines nodes

		   <li> the element name that defines edges

		   <li> the edge attribute name that defines the 'from' node

		   <li> the edge attribute name that defines the 'to' node

		   </ul>

		 */

		public function set xmlNames(array: Array): void {

			_xmlNames = array;

		}

		

	    /** @private */

 		public function addComponent(component: UIComponent): void {
			
 			//bject(component).addYourself(this);

 			//this.addChild(component);

 			this.addChild(component);

 			if(addItemEffect != null) {

 				//addItemEffect.addEventListener(EffectEvent.EFFECT_END, addEffectDone);

	 			addItemEffect.createInstance(component).startEffect();

	 		} else {

	 			//this.addChild(component);

	 		}

 		}

 		

 		/** [for experimental use]. The layout computations are stopped when the amount of motion

 		 * falls below this threshold. I don't know what the units are,

 		 * the range of meaningful values is from 0.001 to 2.0 or so. Low 

 		 * numbers mean that the layout takes longer to settle down, but gives

 		 * a better result. High numbers means that the layout will stop

 		 * sooner, but perhaps with not as nice a layout. 

 		 */

 		public function set motionThreshold(t: Number): void {

 			ForceDirectedLayout.motionLimit = t;

 			dispatchEvent(new Event("motionThresholdChange"));

 		}

 		

 		/** The layout computations are stopped when the amount of motion

 		 * falls below this threshold. */

		[Bindable("motionThresholdChange")]

 		public function get motionThreshold(): Number {

 			return ForceDirectedLayout.motionLimit;

 		}

 		

 		/*

  		private function addEffectDone(event: EffectEvent): void {

  			var component: UIComponent = event.effectInstance.target as UIComponent;

  			this.addChild(component);

  		}

  		*/
		

	    /** @private */

 		public function newComponent(item: Item): UIComponent {
 			var component: UIComponent = createComponent(item);

            component.x = this.width / 2;
            component.y = this.height / 2;

            component.addEventListener("mouseDown", mouseDownEvent);
			component.addEventListener("mouseOver", mouseOverEvent);
			component.addEventListener("mouseOut", mouseOutEvent);
			if(((myItemView)(component)).devPic != null)
				((myItemView)(component)).devPic.addEventListener("mouseDown", devClickEvent);
			if(((myItemView)(component)).statusCircle != null)
				((myItemView)(component)).statusCircle.addEventListener("mouseDown", statusClickEvent);

            //item.addEventListener("doubleClick", doubleClick);

            // double-click event doesn't happen if we are also listening for mouseDown

       	    addComponent(component);
 			return component;
 		}
		
		private function devClickEvent(event: MouseEvent):void  {
			//Alert.show(event.type);
			var now: int = getTimer();
			infoWinMrtg.lock=!infoWinMrtg.lock;
			
			if((now - lastMouseDownTime) < 300) {
				// it's a double-click
				dragParentEnd(event);
				var node: GraphNode = _dataProvider.findNode(UIComponent(event.currentTarget.parent));
				if(node != null && node.item.devPath != "none") {
					trace("double click to dev" + node.item.data.@idx + " " + node.item.data.@ip);
					navigateToURL(new URLRequest(node.item.devPath), "_blank");
					trace("url " + node.item.devPath);
				}
				return;
			}
			lastMouseDownTime = now;
			dragParentBegin(event);
			event.stopImmediatePropagation();
		}
		
		private function statusClickEvent(event: MouseEvent):void  {
			var now: int = getTimer();
			if((now - lastMouseDownTime) < 300) {
				// it's a double-click
				var node: GraphNode = _dataProvider.findNode(UIComponent(event.currentTarget.parent));
				if(node != null && node.item.statePath != "none") {
					trace("double click to status" + node.item.data.@idx + " " + node.item.data.@ip);
					navigateToURL(new URLRequest(node.item.statePath), "_blank");
					trace("url " + node.item.statePath);
				}
				return;
			}
			lastMouseDownTime = now;
		}
		
		private function atkClickEvent(event: MouseEvent):void  {
			var now: int = getTimer();
			if((now - lastMouseDownTime) < 300) {
				// it's a double-click
				var node: GraphNode = _dataProvider.findNode(UIComponent(event.currentTarget.parent));
				if(node != null && node.item.atkLinkPath != "none") {
					trace("double click to attack" + node.item.data.@idx + " " + node.item.data.@ip);
					navigateToURL(new URLRequest(node.item.atkLinkPath), "_blank");
					trace("url " + node.item.atkLinkPath);
				}
				return;
			}
			lastMouseDownTime = now;
		}
		
		public function newComponentXY(item: Item, x:int, y:int): UIComponent {
			var component: UIComponent = createComponent(item);
			if(x == 0 && y == 0)
			{
				component.x = this.width / 2;
				component.y = this.height / 2;
			}
			else
			{
				component.x = x;
				component.y = y;
			}
			component.addEventListener("mouseDown", mouseDownEvent);
			if(((myItemView)(component)).devPic != null)
				((myItemView)(component)).devPic.addEventListener("mouseOver", mouseOverEvent);
			if(((myItemView)(component)).devPic != null)
				((myItemView)(component)).devPic.addEventListener("mouseOut", mouseOutEvent);
			if(((myItemView)(component)).statusCircle != null)
				((myItemView)(component)).statusCircle.addEventListener("mouseOver", mouseOverEvent);
			if(((myItemView)(component)).statusCircle != null)
				((myItemView)(component)).statusCircle.addEventListener("mouseOut", mouseOutEvent);
			if(((myItemView)(component)).atkPic != null)
				((myItemView)(component)).atkPic.addEventListener("mouseOver", mouseOverEvent);
			if(((myItemView)(component)).atkPic != null)
				((myItemView)(component)).atkPic.addEventListener("mouseOut", mouseOutEvent);
			//component.addEventListener("mouseOver", mouseOverEvent);
			//component.addEventListener("mouseOut", mouseOutEvent);
			if(((myItemView)(component)).devPic != null)
				((myItemView)(component)).devPic.addEventListener("mouseDown", devClickEvent);
			if(((myItemView)(component)).statusCircle != null)
				((myItemView)(component)).statusCircle.addEventListener("mouseDown", statusClickEvent);
			if(((myItemView)(component)).atkPic != null)
				((myItemView)(component)).atkPic.addEventListener("mouseDown", atkClickEvent);
			//item.addEventListener("doubleClick", doubleClick);
			// double-click event doesn't happen if we are also listening for mouseDown
			addComponent(component);
			return component;
		}

   	
		
		private var dataGrid:DataGrid = new DataGrid();
		private var dataXMLList:XMLList = new XMLList();

		private function mouseOverEvent(event: MouseEvent):void  {
			var node: GraphNode = _dataProvider.findNode(UIComponent(event.currentTarget.parent));
			if(node != null) {
				
				var iframeMrtg=infoWinMrtg.getChildByName("frame");
				var iframeDev=infoWinDev.getChildByName("frame");
				if(infoWinVisible){
					infoWinMrtg.visible=true;
					infoWinDev.visible=true;
					iframeMrtg.visible=true;
					iframeDev.visible=true;
				}
				
				
				var HasUrl:Boolean = false;
				if(MovieClip(event.currentTarget) == myItemView(event.currentTarget.parent).devPic)
				{
					//Alert.show("1 url:"+node.item.devPath);
					if(String(node.item.devPath).length != 0 && node.item.devPath != "none")
						HasUrl = true;
				
				}
	
				if(MovieClip(event.currentTarget) == myItemView(event.currentTarget.parent).statusCircle)
				{
					if(String(node.item.statePath).length != 0 && node.item.statePath != "none")
						HasUrl = true;
					
				}
				else if(MovieClip(event.currentTarget) == myItemView(event.currentTarget.parent).atkPic)
				{
					if(String(node.item.atkLinkPath).length != 0 && node.item.atkLinkPath != "none")
						HasUrl = true;
				}
				
				if(HasUrl == true)
				{
					MovieClip(event.currentTarget).scaleX = MovieClip(event.currentTarget).scaleX * 1.3;
					MovieClip(event.currentTarget).scaleY = MovieClip(event.currentTarget).scaleY * 1.3;
				}
				
				if(infoWinMrtg.lock==false){
					var ip:String=mrtgDirPath+node.item.data.@ip;
					if(node.item.data.@idx!=""){
						iframeMrtg.source=ip+"/day"+node.item.data.@idx+"minify.html";
					}
					iframeDev.source=ip+"/devicecontent.html";
				//	Alert.show(mrtgDirPath+node.item.data.@ip);
	//				if(ip!="")
		//				iframeDev.source=mrtgDirPath+ip+"/devicecontent.html";
				}
				
				var dataXMLList:XMLList =  
					<>
					<fv>
						<f>Type</f>
						<v>{node.item.data.@nodeType}</v>
					</fv>
					<fv>
						<f>Name</f>
						<v>{node.item.data.@name}</v>
					</fv>
					<fv>
						<f>IP</f>
						<v>{node.item.data.@ip}</v>
					</fv>
					<fv>
						<f>ID</f>
						<v>{node.item.data.@idx}</v>
					</fv>
					</>
		

				dataGrid.rowCount = dataXMLList.length();
				var cols:Array = new Array();
				var gridColumn:DataGridColumn = new DataGridColumn();
				gridColumn.dataField = "f";
				gridColumn.headerText = "Field";
				cols.push(gridColumn);
				var gridColumn2:DataGridColumn = new DataGridColumn();
				gridColumn2.dataField = "v";
				gridColumn2.headerText = "Value";
				
				dataGrid.visible = false;
				this.addChild(dataGrid); /*add to stage before using measureText*/
				
				var textMetrics:TextLineMetrics;
				var textWidth:int = 80;
				textMetrics = dataGrid.measureText(node.item.data.@nodeType);
				if(textMetrics.width > textWidth)
					textWidth = textMetrics.width;
				textMetrics = dataGrid.measureText(node.item.data.@name);
				if(textMetrics.width > textWidth)
					textWidth = textMetrics.width;
				textMetrics = dataGrid.measureText(node.item.data.@ip);
				if(textMetrics.width > textWidth)
					textWidth = textMetrics.width;
				textMetrics = dataGrid.measureText(node.item.data.@idx);
				if(textMetrics.width > textWidth)
					textWidth = textMetrics.width;
				
				gridColumn2.width = textWidth+20;
				
				cols.push(gridColumn2);
				dataGrid.dataProvider = dataXMLList;
				dataGrid.columns=cols;
				dataGrid.resizableColumns = true;
				dataGrid.variableRowHeight = true;
				
				if((dataGrid.x = event.currentTarget.parent.x - dataGrid.width - 50) < 0)
					dataGrid.x = event.currentTarget.parent.x + event.currentTarget.parent.width + 50;

				if((dataGrid.y = event.currentTarget.parent.y - dataGrid.height - 10) < 0)
					dataGrid.y = event.currentTarget.parent.y + dataGrid.height + 10;
				
				dataGrid.visible = true;
			
			}
		}
		
		private function mouseOutEvent(event: MouseEvent):void  {

			var node: GraphNode = _dataProvider.findNode(UIComponent(event.currentTarget.parent));
			if(node != null) {
				var HasUrl:Boolean = false;
				if(MovieClip(event.currentTarget) == myItemView(event.currentTarget.parent).devPic)
				{
					if(String(node.item.devPath).length != 0 && node.item.devPath != "none")
						HasUrl = true;
				}
				if(MovieClip(event.currentTarget) == myItemView(event.currentTarget.parent).statusCircle)
				{
					if(String(node.item.statePath).length != 0 && node.item.statePath != "none")
						HasUrl = true;
				}
				else if(MovieClip(event.currentTarget) == myItemView(event.currentTarget.parent).atkPic)
				{
					if(String(node.item.atkLinkPath).length != 0 && node.item.atkLinkPath != "none")
						HasUrl = true;
				}
				if(HasUrl == true)
				{
					MovieClip(event.currentTarget).scaleX = MovieClip(event.currentTarget).scaleX / 1.3;
					MovieClip(event.currentTarget).scaleY = MovieClip(event.currentTarget).scaleY / 1.3;
				}
				this.removeChild(dataGrid);
			}
		}
		

   		private function mouseDownEvent(event: MouseEvent):void  {
			infoWinMrtg.lock=true;
		//	Alert.show(event.type);

   			var now: int = getTimer();

   			if((now - lastMouseDownTime) < 300) {
   				// it's a double-click
   				var node: GraphNode = _dataProvider.findNode(UIComponent(event.currentTarget));

   				if(node != null) {
					//trace("double click to " + node.item.data.@idx + " " + node.item.data.@ip);

   					dragEnd(event);

   					if(Object(node.view).hasOwnProperty("doubleClick"))
   						Object(node.view).doubleClick(event);	   	
					
					//itemDoubleClick(event);
   				}

   				return;
   			}
			
   			lastMouseDownTime = now;
   			dragBegin(event);
			
   			event.stopImmediatePropagation();
	
   		}
		
		/*to be overrided by roamer*/
		protected function itemDoubleClick(event: MouseEvent):void 
		{			
		}

 

	    /** @private */

   		protected function dragBegin(event: MouseEvent):void  {
   			dragComponent = UIComponent(event.currentTarget);

   			dragStartX = dragComponent.x;

   			dragStartY = dragComponent.y;

   			dragCursorStartX = event.stageX;

   			dragCursorStartY = event.stageY;

   			forceDirectedLayout.setDragNode(_dataProvider.findNode(dragComponent));

   		}

   	

   		private function dragContinue(event: MouseEvent):void  {
   			if(backgroundDragInProgress) {

   				backgroundDragContinue(event);

   				return;

   			}

   			if(dragComponent == null) return;

   			

   			var deltaX: int = event.stageX - dragCursorStartX;

   			var deltaY: int = event.stageY - dragCursorStartY;

   			dragComponent.x = dragStartX + deltaX;

   			dragComponent.y = dragStartY + deltaY;

			refresh();

   		}

   		

   		private function dragEnd(event: MouseEvent):void  {
   			if(backgroundDragInProgress) {

   				backgroundDragEnd(event);

   				return;

   			}

   			dragComponent = null;

   			forceDirectedLayout.setDragNode(null);

   		}
		
		protected function dragParentBegin(event: MouseEvent):void  {
			dragComponent = UIComponent(event.currentTarget.parent);
			dragStartX = dragComponent.x;
			dragStartY = dragComponent.y;
			dragCursorStartX = event.stageX;
			dragCursorStartY = event.stageY;
			forceDirectedLayout.setDragNode(_dataProvider.findNode(dragComponent));
		}

		
		private function dragParentEnd(event: MouseEvent):void  {
			if(backgroundDragInProgress) {
				backgroundDragEnd(event);
				return;
			}
			dragComponent = null;
			forceDirectedLayout.setDragNode(null);
		}



   		private function backgroundMouseDownEvent(event: MouseEvent):void  {
   			var now: int = getTimer();

   			if((now - lastMouseDownTime) < 300) {

   				// it's a double-click

   				//var node: GraphNode = _dataProvider.findNode(UIComponent(event.currentTarget));

   				//if(node != null) {

   				//	dragEnd(event);

   				//	Object(node.view).doubleClick();	   	

   				//}

   				return;

   			}

   			lastMouseDownTime = now;

   			backgroundDragBegin(event);

   			event.stopImmediatePropagation();

   		}



   		private function backgroundDragBegin(event: MouseEvent):void  {
   			//trace("backgroundDragBegin");

   			backgroundDragInProgress = true;

   			/*

   			dragComponent = UIComponent(event.currentTarget);

   			dragStartX = dragComponent.x;

   			dragStartY = dragComponent.y;

   			*/

   			dragCursorStartX = event.stageX;

   			dragCursorStartY = event.stageY;

   			//forceDirectedLayout.setDragNode(_dataProvider.findNode(dragComponent));

   		}

   	

   		private function backgroundDragContinue(event: MouseEvent):void  {
   			//trace("backgroundDragContinue");

   			/*

   			if(dragComponent == null) return;

   			*/

   			var deltaX: int = event.stageX - dragCursorStartX;

   			var deltaY: int = event.stageY - dragCursorStartY;

  			dragCursorStartX = event.stageX;

   			dragCursorStartY = event.stageY;

   			

   			// apply the delta to all components

   			scroll(deltaX, deltaY);

   	        drawingSurface.invalidateDisplayList();


			refresh();

   		}

 		/** @private */

  		protected function scroll(deltaX: int, deltaY: int): void {

   			var c: Array = this.getChildren();

   			for (var i: int = 0; i < c.length; i++) {

   				var itemView: Object = c[i];
				
				if (c[i] is Slider || c[i] is Image || c[i] is MenuBar || c[i] is Button)
				{
					if(!(i == 0 && ((isManual == 1 && backGroundPicMoveEbl != 0 ) ||
						backGroundPicMoveEbl == 2))) /*should not skip background in manual mode for MovEbl = 1 or 2; or any mode for MovEbl = 2*/
						continue;
				}

   				if(itemView != drawingSurface) {
   					itemView.x = itemView.x + deltaX;
   					itemView.y = itemView.y + deltaY;
					if(i == 0)
					{
						this.backGroundPicX += deltaX;
						this.backGroundPicY += deltaY;
					}
   				}

   			}
			
			if(_edgeRenderer != null)
			{
				drawEdges();
			}

  		}

  		

   		private function backgroundDragEnd(event: MouseEvent):void  {

   			//trace("backgroundDragEnd");

   			backgroundDragInProgress = false;

   			/*

   			dragComponent = null;

   			forceDirectedLayout.setDragNode(null);

   			*/

   		}

 		private var locationCacheTime: int = 20 * 60; // 3 min
		private var locationTick: int = 0;
		private var locationCacheCnt: int = 0;

 		/** @private */

        protected function startTimer():void {
            timer = new Timer(50, 1);
            timer.addEventListener(TimerEvent.TIMER_COMPLETE, tick);

            timer.start();
        }

		

		/** @private */

        protected function tick(event:TimerEvent = null):void {
			if(isManual == false)
			{
	        	if(_autoFit) {
	        		autoFitTick();
	        	} else {
					forceDirectedLayout.tick();
	        	}

				this.invalidateDisplayList();
			}
			
			locationTick ++;
			if(locationTick == locationCacheTime)
			{
				locationTick = 0;

				if(locationCacheCnt <= 3)
				{
					//doSaveLocationCache();
					locationCacheCnt ++;
					//Alert.show("locationCacheCnt "+locationCacheCnt);
				}
						
			}
			
			startTimer();

       }

	    /** @private */

        public function get draggedComponent(): UIComponent {

        	var node: GraphNode = GraphNode(forceDirectedLayout.dragNode);

        	if(node == null)

        		return null;

        	return node.view;

        }

		

	    /**
	     *  Redraw everything. Call this when you changed something that
	     * could affect the size of any of the active itemRenderers. There is
	     * no need to call this when the graph data is changed, we update
	     * automatically in that case.
	     */

        public function refresh(): void {
        	if(_dataProvider != null) {
	        	_dataProvider.layoutChanged = true;
	        	if((forceDirectedLayout != null) && _dataProvider.hasNodes/*graph.hasNodes*/) {
		        	forceDirectedLayout.resetDamper();
		        	if(timer == null)
			        	tick();
		        }
	        }
        }



	    /**

	     *  Throw away the dataProvider, leaving an empty graph.

	     */

		public function empty(): void {
        	setDataProvider(new Graph());
        }



	    /**

	     *  Defines the UIComponent class for rendering an item. One instance

	     *  of this class will be created for each item contained in the "dataProvider" property.

	     *  You should specify an itemRenderer if you want every type of Item to have the same kind of view.

	     *  If you want different types of Items to have different views,

	     *  use viewFactory instead.

	     *  

	     *  @default null 

	     */

		public function set itemRenderer(factory: IFactory): void {
			itemRendererFactory = factory;
		}


	    /** @private
	     *  
	     */

 		public function createComponent(item: Item): UIComponent {
 			var result: UIComponent = null;

			if(item is HistorySeed) {
				result = new HistorySeedView();
 			} else {
 				if(_viewFactory != null)
				{
	 				result =_viewFactory.getView(item) as UIComponent;
				}
				
				//trace("result:"+result);
	 			if(result == null) {
	 				if(itemRendererFactory != null)
	 					result = itemRendererFactory.newInstance();
	 				else
	 					result = new DefaultItemView();
	 			}
	 		}

 			if(result is IDataRenderer)
 				(result as IDataRenderer).data = item;

 			return result;
 		}

		

		/*

		private function set distance(d: int): void {

			_dataProvider.distance = d;

			refresh();

		}

		

		private function get distance(): int {

			return _dataProvider.distance;

		}

		*/

		

	    /**

	     *  Defines the data model for this springgraph. The data is 

	     *  a set of items which can be  linked to each other. You can provide the

	     *  data as XML, or as a Graph object. 

	     *  <p>

	     * To use XML, provide an object of type XML with the following format:

	     * <ul>

	     * <li>root element can have any name; attributes are ignored</li>

	     * <li>items are defined by elements whose name is 'Node', which must have a unique 'id' attribute.</li>

	     * <li>links are defined by elements whose name is 'Edge', which must have attributes 'fromID' and 'toID', which

	     * reference the id of the 2 items connect by a link.</li>

	     * <li>you can have any nesting structure you like, we ignore it.</li>

	     * <li>namespaces are not currently supported</li>

	     * </ul>

	     * <p>When the dataProvider is set to XML, we automatically create a Graph that repesents the items and links

	     * in the XML data. Each itemRenderer's 'data' property is set to the Item object whose 'id' 

	     * is the id of an XML Node, and whose 'data' property is the XML object representing the Node.

	     * You can use the xmlNames property to define the names that you have used in your XML data.

	     * The default XML names 'Node', 'Edge', 'fromID', and 'toID'.</p>

	     *  @default null 

	     */

		public function set dataProvider(obj: Object): void {
			setDataProvider(obj);
		}

		

		public function get dataProvider(): Object {
			return _graph;
		}

		

		private function setDataProvider(obj: Object): void {
			if(creationIsComplete) {
				doSetDataProvider(obj);
			} else {
				pendingDataProvider = obj;
			}
		}
		
		private var creationIsComplete: Boolean = false;
		private var pendingDataProvider: Object = null;

		private function doSetDataProvider(obj: Object): void {
			if(obj is XML)
				obj = Graph.fromXML(obj as XML, _xmlNames);

			_graph = obj as Graph;
			rebuild();
			_graph.addEventListener(Graph.CHANGE, graphChangeHandler);
		}

		

	    /**

	     *  The color we use to draw the lines that represent links between items.

	     *  

	     *  @default 0xcccccc 

	     */

		public function set lineColor(color: int): void {

			_lineColor = color;

			refresh();

		}

		

	    /**

	     *  How strongly do items push each other away.

	     *  

	     *  @default 0.75 

	     */

		public function set repulsionFactor(factor: Number): void {

			_repulsionFactor = factor;

			refresh();

		}

		

		[Bindable(event="repulsionFactorChanged")]

		public function get repulsionFactor(): Number {

			return _repulsionFactor;

		}

		

		/** @private */

		public function graphChangeHandler(event: Event): void {

			rebuild();

		}

		

		/** A factory that can create views for specific Items. This is an instance of

		 * a class (or component) that implements the IViewFactory interface.

 	     *  You should specify only one of itemRenderer or viewFactory.

		 */
		public function set viewFactory(factory: IViewFactory): void {

			_viewFactory = factory;

		}

		public function get viewFactory(): IViewFactory {
			return _viewFactory;
		}

		/** Defines an Edge Renderer object that we will use to render edges.

		 * If this is null, we use our built-in edge renderer.

		 */

		public function set edgeRenderer(renderer: IEdgeRenderer): void {

			_edgeRenderer = renderer;

		}
		

		

		/** Enable/disable the auto-fit feature. When enabled, we automatically

		 * and continuously adjust the 'repulsionFactor' property, as well as scroll the

		 * viewing area of the roamer, so that the graph

		 * items are entirely contained within, and nicely spread out over

		 * the entire rectangle of this component. When disabled, we obey whatever

		 * value you set into the 'repulsionFactor' property, and scrolling

		 * must be done manually. When autoFit is enabled, you may still

		 * set repulsionFactor and scroll - the component will smoothly continue

		 * from wherever you left it. */

		public function set autoFit(value: Boolean): void {

			_autoFit = value;

		}

		

		private function rebuild(): void {

			if((_graph != null) && (_dataProvider != null)) {

	   	        _dataProvider.graph = _graph;

				refresh();

			}

		}

		

		/** the implemenation of auto-separation, which runs on every drawing cycle.

		 * The algorithm continuously adjusts repulsionFactor to try and keep the

		 * available screen space filled to about 90%. (FYI, all of the numbers and

		 * coefficients have been hand-tuned for the RoamerDemo sample on my laptop

		 * screen. I can't guarantee they work well in all situations, let me know

		 * if there are problems). (mark s. nov 2006)

		 * @private

		 */

		private function autoFitTick():void {

 			// do a layout pass

			forceDirectedLayout.tick();

			

			// find out the current rect occupied by all items

			var itemBounds: Rectangle = calcItemsBoundingRect();

			//trace("top: " + itemBounds.top + "left, : " + itemBounds.left + "bottom, : " + itemBounds.bottom + "right, : " + itemBounds.right);

			if(itemBounds != null) {

				// find out how much of the available space is currently in use

				var vCoverage: Number = (itemBounds.bottom - itemBounds.top) / this.height;

				var hCoverage: Number = (itemBounds.right - itemBounds.left) / this.width;

				var coverage: Number = Math.max(hCoverage, vCoverage);

				

				if((prevCoverage > 0) && (coverage > 0)) {

					// our ideal coverage is 90%. Find out how close we are to that.

					var distance: Number = 0.9 - coverage;

					if (Math.abs(distance) > 0.03) {

						// We are more than 3% away from the ideal coverage

						

						// Find out how much the coverage has changed in the last tick

						// A positive delta means the space occupied by our items

						// is expanding, negative means it's contracting

						var deltaCoverage: Number = coverage - prevCoverage;

						

						// Figure out how quickly we want to expand or contract.

						// The further away we are from the target coverage, the more quickly

						// we want the coverage to change. But we don't want to change it

						// too quickly, because we don't to overshoot, we don't want to

						// accelerate or decelerate too fast.

						var targetDelta: Number = distance * 0.2;

						if(targetDelta < -0.01) targetDelta = -0.01;

						if(targetDelta > 0.01) targetDelta = 0.01;

						

						if(deltaCoverage < targetDelta) {

							// we're not expanding fast enough. crank up the repulsion,

							_repulsionFactor = _repulsionFactor + 0.01;

							// (but not too much!)

							if(_repulsionFactor > 0.7)

								_repulsionFactor = 0.7;

						} else {

							// we're not contracting fast enough. crank down the repulsion. 

							_repulsionFactor = _repulsionFactor - 0.01;

							// (but not too much!)

							if(_repulsionFactor < 0.05)

								_repulsionFactor = 0.05;

						}

						//trace("rep " + this._repulsionFactor + ", coverage " + coverage 

						//	+ ", delta " + deltaCoverage + ", target " + targetDelta);

					}

				}

				prevCoverage = coverage;



				if((itemBounds.left < 0) || (itemBounds.top < 0) || (itemBounds.bottom > this.height) || (itemBounds.right > this.width)) {

					// some items are off the screen. Let's auto-scroll the display.

					

					// calculate how far we have to center all the items on screen in the X direction

					var scrollX: int = (this.width / 2) - (itemBounds.x + (itemBounds.width / 2));

					// limit it to a few pixels at a time, I think this looks nicer

					if(scrollX < -1) scrollX = -1;

					if(scrollX > 1) scrollX = 1;

					

					// do the same for the Y direction

					var scrollY: int = (this.height / 2) - (itemBounds.y + (itemBounds.height / 2));

					if(scrollY < -1) scrollY = -1;

					if(scrollY > 1) scrollY = 1;

					

					// do the scrolling

					if((scrollX != 0) || (scrollY != 0))

						scroll(scrollX, scrollY);

				}

 			}

			if(prevRepulsionFactor != _repulsionFactor) {

				prevRepulsionFactor = _repulsionFactor;

				dispatchEvent(new Event("repulsionFactorChanged"));

			}

        }

		

  		private function calcItemsBoundingRect(): Rectangle {

   			var c: Array = this.getChildren();

   			if(c.length == 0) return null;



			var result: Rectangle = new Rectangle(9999999, 9999999, -9999999, -9999999);

   			for (var i: int = 1; i < c.length; i++) {

   				var itemView: Object = c[i];
				
				if (c[i] is Slider || c[i] is Image || c[i] is MenuBar || c[i] is Button || c[i] is DataGrid)
					continue;
				

   				if(itemView != drawingSurface) {

		    		if(itemView.x < result.left) result.left = itemView.x;

		    		if((itemView.x + itemView.width) > result.right) result.right = itemView.x + itemView.width;

		    		if(itemView.y < result.top) result.top = itemView.y;

		    		if((itemView.y + itemView.height) > result.bottom) result.bottom = itemView.y + itemView.height;

   				}

   			}

   			return result;

  		}
		



	    /** @private */
		protected var _dataProvider:GraphDataProvider = null;

	    /** @private */
		public var distinguishedItem: Item;

	    /** @private */
		protected var _lineColor: int = 0xcccccc;

	    /** @private */
		public var distinguishedLineColor: int = 0xff0000;

	    /** @private */
		public var _repulsionFactor: Number = 0.75;

	    /** @private */
		public var defaultRepulsion: Number = 100;

	    /** @private */
		protected var forceDirectedLayout: ForceDirectedLayout = null;

		/** @private */
		protected var drawingSurface: UIComponent; // we can't use our own background for drawing, because it doesn't scroll

		/** @private */
		protected var fullGraph: Graph;
		protected var _graph: Graph;

		/** @private */

		protected var _xmlNames: Array;

        private var timer:Timer;
		private var itemRendererFactory: IFactory = null;
        private var dragComponent: UIComponent;
        private var dragStartX: int;
        private var dragStartY: int;
        private var dragCursorStartX: int;
        private var dragCursorStartY: int;
        private var lastMouseDownTime: int = -999999;
        private var paused: Boolean = false;
        private var backgroundDragInProgress: Boolean = false;
        private var _viewFactory: IViewFactory = null;
        private var _edgeRenderer: IEdgeRenderer = null;
		private var _autoFit: Boolean = false;
		private var prevCoverage: Number = 0;
  		private var prevRepulsionFactor: Number = 0;
		protected var menuBar:MenuBar = null;
		protected var backGroundPicX:int = 10;
		protected var backGroundPicY:int = 10;
		protected var backGroundPicMoveEbl:int = 1;
		public var refreshRedirTimer:Number = 0;
	}
 

}


import com.adobe.flex.extras.controls.forcelayout.IForEachNode;
import com.adobe.flex.extras.controls.forcelayout.Node;
import com.adobe.flex.extras.controls.springgraph.GraphNode;
import com.adobe.flex.extras.controls.springgraph.myItemView;

import flash.text.TextFormat;

class Scaler implements IForEachNode {
	
	private var _scaleDelta:Number;
	
	public function Scaler(scaleDelta:Number):void
	{
		_scaleDelta = scaleDelta;
	}
	
	public function forEachNode( n: Node ): void {
		if( (GraphNode)(n).view.scaleX + _scaleDelta >= 0)
			(GraphNode)(n).view.scaleX += _scaleDelta;
		if( (GraphNode)(n).view.scaleY + _scaleDelta >= 0)
			(GraphNode)(n).view.scaleY += _scaleDelta;
	}
}

class LocationChanger implements IForEachNode {
	
	private var _locationDelta:Number;
	private var _centralX:Number;
	private var _centralY:Number;
	
	public function LocationChanger(locationDelta:Number, centralX:Number, centralY:Number):void
	{
		_locationDelta = locationDelta;
		_centralX = centralX;
		_centralY = centralY;
	}
	
	public function forEachNode( n: Node ): void {
		(GraphNode)(n).view.x += ((GraphNode)(n).view.x - _centralX) * _locationDelta;
		(GraphNode)(n).view.y += ((GraphNode)(n).view.y - _centralY) * _locationDelta;
	}
}

class AlphaChanger implements IForEachNode {
	
	private var _newAlpha:Number;
	
	public function AlphaChanger(newAlpha:Number):void
	{
		_newAlpha = newAlpha;
	}
	
	public function forEachNode( n: Node ): void {
		(myItemView)((GraphNode)(n).view).devPic.alpha = _newAlpha;
		if(_newAlpha == 0)
			(myItemView)((GraphNode)(n).view).txt.y = (myItemView)((GraphNode)(n).view).devPic.height/2;
		else
			(myItemView)((GraphNode)(n).view).txt.y = (myItemView)((GraphNode)(n).view).devPic.height;
	}
}

class FontSizeChanger implements IForEachNode {
	
	private var _newFontSize:int;
	
	public function FontSizeChanger(newFontSize:int):void
	{
		_newFontSize = newFontSize;
	}
	
	public function forEachNode( n: Node ): void {
		var tf:TextFormat = new TextFormat('',_newFontSize);
		var itemView:myItemView = (myItemView)((GraphNode)(n).view);
		itemView.txt.setTextFormat(tf);
		itemView.txt.x = (itemView.width - itemView.txt.width)/2;
	}
}


