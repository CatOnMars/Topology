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
	import com.adobe.flex.extras.controls.forcelayout.Node;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.media.SoundMixer;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.controls.MenuBar;
	import mx.events.MenuEvent;
	import mx.styles.StyleManager;


	/**
	 *  Dispatched when there is any change to the nodes and/or links of this graph.
	 *
	 *  @eventType flash.events.Event
	 */
	[Event(name="change", type="flash.events.Event")]

	/**
	 * An extension to SpringGraph that restricts the visible items to a subset of the full graph.
	 * You can control which items are currently visible by using the <code>itemLimit</code>, 
	 * <code>maxDistanceFromCurrent</code>, and <code>currentItem properties</code>.
	 */ 
	public class Roamer extends SpringGraph {
		
		private var timer:Timer; 
		
		private var urConfigXML:URLRequest  = new URLRequest();
		private var ulConfigXML:URLLoader;
		
		private var urRightClickMenu:URLRequest  = new URLRequest();
		private var loaderRightClickMenu:URLLoader;
		
		private var urTreeParser:URLRequest  = new URLRequest();
		private var loaderTreeParser:URLLoader;
		
		private var urMenuBarXML:URLRequest = new URLRequest();
		private var ulMenuBarXML:URLLoader;
		
		private var urTreeXML:URLRequest = new URLRequest();
		private var ulTreeXML:URLLoader;

		private var urStatus:URLRequest = new URLRequest();
		private var loaderStatus:URLLoader;
		
		private var urRedirect:URLRequest = new URLRequest();
		private var loaderRedirect:URLLoader;
		
		private var urAttack:URLRequest = new URLRequest();
		private var loaderAttack:URLLoader;
		
		public var saveCfgPHPName:String = "saveCfg.php";
		private var urSaveConfig:URLRequest = new URLRequest();
		private var loaderSaveConfig:URLLoader;
		
		private var urLoad:URLRequest = new URLRequest();
		private var loaderLoad:URLLoader;
		

		
		private var header:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
		
		private var treeXml:XML;
		private var lineXml:XML;
		private var menuXml:XML;
		private var attackXml:XML;
		private var configXml:XML;
		public var roamerIdx:int;
		
		private var locationXml:XML;
		
		
		[Bindable]
		/**
		 * The maximum number of items that are visible at any time.
		 */
		public function get itemLimit(): int {
			return _itemLimit;
		}
		
		public function set itemLimit(i: int): void {
			_itemLimit = i;
			recreateGraph();
		}
		
		/**
		 * We only display items that are within this distance from the current item.
		 */
		public var maxDistanceFromCurrentTmp;
		
		public function set maxDistanceFromCurrent(i: int): void {
			_maxDistanceFromCurrent = i;
			recreateGraph();
		}
		
		public function get maxDistanceFromCurrent(): int {
			return _maxDistanceFromCurrent;
		}
	
		/**
		 * The item that current acts as the 'center' or 'root' of the graph. 
		 * This item defines the subset of the graph that will be visible.
		 */
		public function set currentItem(item: Item): void {
			newCurrentItem(item);
			recreateGraph();
			dispatchEvent(new Event("currentItemChange"));
		}

		[Bindable("currentItemChange")]
		public function get currentItem(): Item {
			return _currentItem;
		}

		/** Find out if a given item has ever been the currentItem.
		 * @param item an Item that is contained in this graph
		 * @returns true if the indicated item has ever been the currentItem of this graph.
		 */
		public function hasBeenCurrentItem(item: Item): Boolean {
			return allCurrentItems.hasOwnProperty(item.id);
		}
		
		[Bindable("dataProviderChange")]
		/**
		 * Defines the data model for this springgraph. See SpringGraph.dataProvider
		 * for more information. */
		override public function get dataProvider(): Object {
			return fullGraph;
		}

		/** sets the data provider and chooses the initial currentItem.
		 */
		public function setDataProvider(dp: XML, currentId: String): void {
			var g: Graph = Graph.fromXML(dp, _xmlNames);
			g.distinguishedItem = g.find(currentId);
			doSetDataProvider(g);
		}

		override public function set dataProvider(obj: Object): void {
			if(obj is XML)
				obj = Graph.fromXML(obj as XML, _xmlNames);
			doSetDataProvider(obj as Graph);
		}
		
		/** Calulate the distance between 2 items. Currently this is a fast-but-cheezy 
		 * calculation that returns 0 (if the 2 items are the same), 1 (if the 2 items
		 * are linked), or 99 otherwise. 
		 * @return the distance between the two items. 
		 */
		public function distance(fromItem: Item, toItem: Item): int {
			if(fromItem == toItem)
				return 0;
			if(arrayIncludes(fullGraph.neighbors(fromItem.id), toItem))
				return 1;
			return 99;
		}

		/** The total number of items in the dataProvider.
		 */
		public function get fullNodeCount(): int {
			if(fullGraph != null)
				return fullGraph.nodeCount;
			return 0;
		}
		
		/** The number of items in the dataProvider that are currently visible.
		 */
		public function get visibleNodeCount(): int {
			if(_graph != null)
				return _graph.nodeCount;
			return 0;
		}
		
		/** An array of items that will not be displayed, even if they 
		 * are chosen to be visible by the Roamer's other computations.
		 */
		private var forceInvisible: Array = null;
		
		/** An array of items that will be displayed on the graph, even if they 
		 * are not chosen to be visible by the Roamer's other computations.
		 */
		private var forceVisible: Array = null;
		
		/** Call this function after modifying the forceInvisible or forceVisible properties */
		private function recreate(): void {
			recreateGraph();
		}

		[Bindable("showHistoryChange")]
		/** If true, then all items that have been the 'current item' are made visible.
		 * 
		 * */
		public function get showHistory(): Boolean {
			return _showHistory;
		}
		
		public function set showHistory(show: Boolean): void {
			//this.forceVisible = show ? history : null;
			dispatchEvent(new Event("showHistoryChange"));
			_showHistory = show;
			var temp: Item = _currentItem;
			_currentItem = null;
			recreate();
			_currentItem = temp;
			recreate();
		}
		
		/** Forget which items have been the current item. This will affect the history
		 * used by 'showHistory' and 'hasBeenCurrentItem'.
		 * 
		 * */
		public function resetHistory(): void {
			allCurrentItems = new Array();
			_history = new Array();
			dispatchEvent(new Event("historyChange"));
		}
		
		/** Force the item to be shown, even if it is outside the limits set by 
		 * 'maxDistanceFromCurrent'. 
		 * */
		public function showItem(item: Item): void {
			if(forceVisible == null)
				forceVisible = [];
			forceVisible.push(item);
			recreate();
		}
		
		
		/** Force the item to not be shown, even if it is inside the limits set by 
		 * 'maxDistanceFromCurrent'. 
		 * */
		public function hideItem(item: Item): void {
			if(forceInvisible == null)
				forceInvisible = [];
			forceInvisible.push(item);
			recreate();
		}
		
		/** Cancels the effect of any prior calls to hideItem and/or showItem.
		 * */
		public function resetShowHide(): void {
			forceVisible = null;
			forceInvisible = null;
		}
		
		/** Sets the currentItem to the previous history Item. "historyIndex" will be decremented.
		 *  Has no effect if historyIndex is already 0. */
		public function back(): void {
			if (historyCurrentlyViewed > 0) {
				historyCurrentlyViewed--;
				_currentItem = _history[historyCurrentlyViewed];
				recreateGraph();
				dispatchEvent(new Event("currentItemChange"));
			}
		}
				
		/** Sets the currentItem to the next history Item. "historyIndex" will be incremented.
		 *  Has no effect if historyIndex is already the highest possible index in "history". */
		public function forward(): void {
			if(historyCurrentlyViewed < (_history.length - 1)) {
				historyCurrentlyViewed++;
				_currentItem = _history[historyCurrentlyViewed];
				recreateGraph();
				dispatchEvent(new Event("currentItemChange"));
			}
		}
		
		[Bindable("currentItemChange")]
		/** Whether the back() function will have any effect at the moment. */
		public function get backOK(): Boolean {
			return (historyCurrentlyViewed > 0);
		}
		
		[Bindable("currentItemChange")]
		/** Whether the forward() function will have any effect at the moment */
		public function get forwardOK(): Boolean {
			return (historyCurrentlyViewed < (_history.length - 1));
		}
		
		[Bindable("historyChange")]
		/** An ordered list of all the items that been the current item. */
		public function get history(): Array {
			return _history;
		}
		
		[Bindable("currentItemChange")]
		/** The index into "history" that corresponds to the currentItem.
		 * Can be any number between 0 and the index of the most recent history entry.
		 * Usually this is simply the index of the most recent history entry. 
		 * However, if you've used back() or forward() then this index will vary. You can also 
		 * set this index to any valid value; this will cause currentItem to become
		 * the corresponding history item.
		  */
		public function get historyIndex(): int {
			return historyCurrentlyViewed;
		}

		public function set historyIndex(i: int): void {
			if ((i >= 0) && (i < _history.length)) {
				historyCurrentlyViewed = i;
				_currentItem = _history[historyCurrentlyViewed];
				recreateGraph();
				dispatchEvent(new Event("currentItemChange"));
			}
		}
		
		[Bindable("tidyHistoryChange")]
		/** Keeps all visibleHistoryItems clustered together. If this is set to false,
		 * history items tend to form a long chain that makes the autoFit mode tend
		 * to shrink the repulsionFactor excessively. */
		public function get tidyHistory(): Boolean{
			return _tidyHistory;
		}

		public function set tidyHistory(b: Boolean): void {
			_tidyHistory = b;
			recreateGraph();
			dispatchEvent(new Event("tidyHistoryChange"));
		}
		
		[Bindable("visibleHistoryItemsChange")]
		/** A list of all the items that are currently visible only 
		 * because showHistory is enabled. In other words this list 
		 * is the entire history minus the items that are currently visible anyway. */
		public function get visibleHistoryItems(): Object{
			return _visibleHistoryItems;
		}
		private function set visibleHistoryItems(o: Object): void { }
				
		public var rmVlan:Boolean = false;
		public var rmGroup:Boolean = false;
		public var rmLine:Boolean = false;

		/*to be overrided by roamer*/
		override protected function updateCurrentItem(itemID:String):void 
		{
			var item:Item, itemTmp:Item;
			item = fullGraphWithVlan.find(itemID);
			_currentItem = item;

			if(item != null)
			{
				fullGraphWithVlan.updateFromXML(treeXml, lineXml, null, rmVlan, rmGroup, rmLine, item.id);
			}
			/*else
				_maxDistanceFromCurrent = maxDistanceFromCurrentTmp;*/

			for each (var location: XML in locationXml.descendants("location")) {
				itemTmp = fullGraphWithVlan.find(location.@id);
				if(itemTmp != null)
				{
					itemTmp.X = location.@x;
					itemTmp.Y = location.@y;
				}
			}
					
			//recreateGraph();
			doSetDataProvider(fullGraphWithVlan);
			item = fullGraphWithVlan.find(itemID);
			_currentItem = item;
			/*if(item.data.@nodeType == "Router")
				_skipItem = item.parentItem;
			else
				_skipItem = item.parentItem;*/
			//_maxDistanceFromCurrent = maxDistanceFromCurrentTmp;
			recreateGraph();
			//this.loadRedirect();
			
			refreshRedirTimer = 1;
			
			dispatchEvent(new Event("currentItemChange"));
		}
		
		/*to be overrided by roamer*/
		override protected function itemDoubleClick(event: MouseEvent):void 
		{
			_currentItem = event.currentTarget.data;
			recreateGraph();
			dispatchEvent(new Event("currentItemChange"));
		}
		
		/*to be overrided by roamer*/
		override protected function reDrawItems():void 
		{			
			var item:Item = _currentItem;
			
			doSetDataProvider(fullGraph);
			_currentItem = item;
			recreateGraph();
			dispatchEvent(new Event("currentItemChange"));
		}
		
		/*to be overrided by roamer*/
		override protected function updateDistance(distance:int):void 
		{			
			_maxDistanceFromCurrent = distance;
			recreateGraph();
		}
		
		/*to be overrided by roamer*/
		override protected function updateMaxNode(maxNode:int):void 
		{			
			_itemLimit = maxNode;
			recreateGraph();
		}
		
		/*overwrited by roamer*/
		override protected function setItemTxt():void
		{
			updateCurrentItem(_currentItem.id);
		}
		
		/*to be overrided by roamer*/
		override protected function setHideVlan(hideVlan:Boolean):void 
		{			
			rmVlan = hideVlan;
			updateCurrentItem(_currentItem.id);
		}
		
		/*to be overrided by roamer*/
		override protected function setHideGroup(hideGroup:Boolean):void 
		{			
			rmGroup = hideGroup;
			updateCurrentItem(_currentItem.id);
		}
		
		/*to be overrided by roamer*/
		override protected function setHideLine(hideLine:Boolean):void 
		{			
			rmLine = hideLine;
			updateCurrentItem(_currentItem.id);
		}
		
		private var dfltCenterID:String = "";
		private var dfltShowBG:Boolean = false;
		private var dfltShowStatus:Boolean = false;
		private var dfltShowRate:Boolean = false;
		private var dfltShowRateInfo:Boolean = false;		
		private var dfltShowAttack:Boolean = false;
		private var dfltAtkIsoX:int = 50;
		private var dfltAtkIsoY:int = 0;
		private var dfltIdentify:String = "ip";
		private var dfltDistance:int = 8;
		private var dfltMaxNode:int = 25;
		private var dfltManual:Boolean = false;
		private var dfltAutoFit:Boolean = false;
		private var dfltAlpha:Number = 1.0;
		private var dfltFontSize:int = 24;
		private var dfltDevFontColor:int = 0x000000;
		private var dfltRateFontColor:int = 0x000000;
		private var dfltRateLine:int = 2;
		private var dfltRefreshInterval:int = 5;
		private var dfltRepulsion:Number = 1.0;
		private var dfltScale:Number = 0.8;
		private var dfltNumNodeFontSize:int = 30;
		private var dfltNumNodeFontColor:int = 0xff00000;
		private var dfltTreePath:String="./nbadroute.tree";
		private var dfltLinePath:String="./nbadroute.line";
		private var dfltAtkPath:String="./nbadroute.atk";
		private var dfltStatusPath:String="./nbadroute.status";
		private var dfltRedirectPath:String="./redirect.txt";
		public var dfltMrtgPathFlashView:String="../mrtgdata/";
		private var dfltMrtgPathPHPView:String="./mrtgdata/";
		private var dfltEncoding:String="big5";
		private var dfltHideVlan:Boolean=true;
		private var dfltHideGroup:Boolean=true;
		private var dfltHideLine:Boolean=true;
		private var dfltSaveButtonX:int = 180;
		private var dfltSaveButtonY:int = 0;
		private var dfltManualButtonX:int = 239;
		private var dfltManualButtonY:int = 0;
		private var dfltBackGroundColor:int = 0xffffff;
		private var dfltBackGroundPic:String;
		private var backGroundPic:Image;
		
		
		public function initTopology():void {
			loadDefaultConfig();
		}
		
		public function loadDefaultConfig():void {
			urConfigXML.url =  dfltPHPDIR + "dfltConfig" + roamerIdx + ".xml";
			urConfigXML.method = URLRequestMethod.GET;
			urConfigXML.requestHeaders.push(header);
			urConfigXML.data = new URLVariables("time="+Number(new Date().getTime()));
			ulConfigXML = new URLLoader();
			ulConfigXML.load(urConfigXML);
			ulConfigXML.addEventListener(Event.COMPLETE, setDefaultConfig);
		}
		
		private function setDefaultConfig(ev:Event):void {
			configXml =  new XML(ulConfigXML.data);
			
			dfltCenterID = configXml.dfltCenterID.@value;
			currentIDLog = configXml.dfltCenterID.@value;
			
			if(configXml.showBG.@value == "true")
				dfltShowBG = true;
			else
				dfltShowBG = false;
			showBGLog = configXml.showBG.@value;
			
			if(configXml.showStatus.@value == "true")
				dfltShowStatus = true;
			else
				dfltShowStatus = false;
			showStatusLog = configXml.showStatus.@value; 
			
			if(configXml.showRate.@value == "true")
				dfltShowRate = true;
			else
				dfltShowRate = false;
			showRateLog = configXml.showRate.@value;
			
			if(configXml.showRateInfo.@value == "true")
				dfltShowRateInfo = true;
			else
				dfltShowRateInfo = false;
			showRateInfoLog = configXml.showRateInfo.@value;
			
			if(configXml.showAttack.@value == "true")
				dfltShowAttack = true;
			else
				dfltShowAttack = false;
			showAttackLog = configXml.showAttack.@value;
			
			if(configXml.atkIsoX.@value != null)
				dfltAtkIsoX = configXml.atkIsoX.@value;
			if(configXml.atkIsoY.@value != null)
				dfltAtkIsoY = configXml.atkIsoY.@value;
			
			dfltIdentify = configXml.identify.@value;
			txtLog = configXml.identify.@value;
			
			dfltDistance = configXml.distance.@value;
			distanceLog = configXml.distance.@value;
			
			dfltMaxNode = configXml.maxNode.@value;
			nodeLog = configXml.maxNode.@value;
			
			if(configXml.manual.@value == "true")
				dfltManual = true;
			else
				dfltManual = false;
			manualLog = configXml.manual.@value; 
			
			if(configXml.autoFit.@value == "true")
				dfltAutoFit = true;
			else
				dfltAutoFit = false;
			dfltAlpha = configXml.alpha.@value;
			alphaLog = configXml.alpha.@value;
			dfltFontSize = configXml.fontSize.@value;
			fontSizeLog = configXml.fontSize.@value;
			dfltDevFontColor = configXml.devFontColor.@value;
			dfltRateFontColor = configXml.rateFontColor.@value;
			dfltRateLine = configXml.rateLine.@value;
			rateLineLog = configXml.rateLine.@value;
			dfltRepulsion = configXml.repulsion.@value;
			dfltScale = configXml.scale.@value;
			scaleLog = configXml.scale.@value;
			dfltNumNodeFontSize = configXml.numNodeFontSize.@value;
			dfltNumNodeFontColor = configXml.numNodeFontColor.@value;
			dfltBackGroundColor = configXml.backGroundColor.@value;
			dfltTreePath=configXml.treeFilePath.@value;
			dfltLinePath=configXml.lineFilePath.@value;
			dfltAtkPath=configXml.atkFilePath.@value;
			dfltStatusPath=configXml.statusFilePath.@value;
			dfltRedirectPath=configXml.redirectFilePath.@value;
			dfltMrtgPathFlashView=configXml.mrtgDirPathFlashView.@value;
			dfltMrtgPathPHPView=configXml.mrtgDirPathPHPView.@value;
			dfltEncoding=configXml.charEncoding.@value;
			if(configXml.hideVlan.@value == "true")
				dfltHideVlan = true;
			else
				dfltHideVlan = false;
			hideVlanLog = configXml.hideVlan.@value;
			if(configXml.hideGroup.@value == "true")
				dfltHideGroup = true;
			else
				dfltHideGroup = false;
			hideGroupLog = configXml.hideGroup.@value;
			 
			if(configXml.hideLine.@value == "true")
				dfltHideLine = true;
			else
				dfltHideLine = false;
			hideLineLog = configXml.hideLine.@value;
			
			dfltSaveButtonX=configXml.saveButtonX.@value;
			dfltSaveButtonY=configXml.saveButtonY.@value;
			dfltManualButtonX=configXml.manualButtonX.@value;
			dfltManualButtonY=configXml.manualButtonY.@value;
			sndIdx["Bad"]=configXml.sndMenu.@Bad;
			sndIdx["Alarm"]=configXml.sndMenu.@Alarm;
			sndIdx["Victim"]=configXml.sndMenu.@Victim;
			dfltBackGroundPic=configXml.backGroundPic.@value;

			if(configXml.backGroundPicMoveEbl.@value != null)
				this.backGroundPicMoveEbl=configXml.backGroundPicMoveEbl.@value;
			
			if(dfltBackGroundPic != null && dfltBackGroundPic != "none")
			{
				this.backGroundPic = new Image();
				this.backGroundPic.source = dfltBackGroundPic;
				this.backGroundPicX=configXml.backGroundPicX.@value;
				this.backGroundPicY=configXml.backGroundPicY.@value;				
				this.backGroundPic.x = this.backGroundPicX;
				this.backGroundPic.y = this.backGroundPicY;
				this.backGroundPic.enabled = true;
				var cTmp:DisplayObject;
				
				cTmp=this.getChildAt(0);
				this.removeChildAt(0);
				this.addChild(this.backGroundPic);
				this.addChild(cTmp);
				if(dfltShowBG == false)
					this.backGroundPic.visible = false;
			}
			else
				this.backGroundPic.enabled = false;
			
			if(configXml.wheelScale.@value != null)
			{
				wheelScale = configXml.wheelScale.@value;
				wheelScaleLog = configXml.wheelScale.@value;
			}
			if(configXml.wheelLocation.@value != null)
			{
				wheelLocation = configXml.wheelLocation.@value;
				wheelLocationLog = configXml.wheelLocation.@value;
			}
			
			if((dfltBackGroundPic != null && dfltBackGroundPic != "none") && dfltShowBG == true)
			{
				wheelLocation = 0;
			}
			
			this.infoWinMrtg_width = configXml.infoWinMrtg_width.@value;
			this.infoWinMrtg_height = configXml.infoWinMrtg_height.@value;
			

			this.infoWinDev_width = configXml.infoWinDev_width.@value;
			this.infoWinDev_height = configXml.infoWinDev_height.@value;
			
			updateInfoWindowSize();
			
			
			ulConfigXML.close();
			loadRightClickMenu();
		}
		
		public var lang:String = "";
		
		private function loadRightClickMenu():void
		{
			urRightClickMenu.url =  dfltPHPDIR + "clickEvent" + lang + ".xml";
			trace("click url " + urRightClickMenu.url);
			urRightClickMenu.method = URLRequestMethod.GET;
			urRightClickMenu.requestHeaders.push(header);
			urRightClickMenu.data = new URLVariables("time="+Number(new Date().getTime()));
			loaderRightClickMenu = new URLLoader();
			loaderRightClickMenu.load(urRightClickMenu);
			loaderRightClickMenu.addEventListener(Event.COMPLETE, applyDfltConfig);	
		}
		
		var clickEventXml:XML;
		
		private function applyDfltConfig(ev:Event):void
		{
			clickEventXml = new XML(loaderRightClickMenu.data);
			loaderRightClickMenu.close();
			
			this.showHistory = false;
			this.setStyle("backgroundColor", String(dfltBackGroundColor));
			
			this.itemLimit = dfltMaxNode;
			this.maxDistanceFromCurrent = dfltDistance;
			this.maxDistanceFromCurrentTmp = dfltDistance;
			this.repulsionFactor = dfltRepulsion;
			this.autoFit = dfltAutoFit;
			this.rmVlan = dfltHideVlan;
			this.rmGroup = dfltHideGroup;
			this.rmLine = dfltHideLine;			
			
			var viewFactory:myViewFactory = new myViewFactory();
			viewFactory.setClickEventXML(clickEventXml);
			viewFactory.itemScale = dfltScale;
			viewFactory.showStatus = dfltShowStatus;
			viewFactory.showAttack = dfltShowAttack;
			viewFactory.txtInfo = dfltIdentify;
			viewFactory.txtFontSize = dfltFontSize;
			viewFactory.txtFontColor = dfltDevFontColor;
			this.txtFontColor = dfltRateFontColor;
			if(tfRate != null)
				tfRate.color = String(dfltRateFontColor);
			viewFactory.numNodeFontSize = dfltNumNodeFontSize;
			viewFactory.numNodeFontColor = dfltNumNodeFontColor;
			viewFactory.viewAlpha = dfltAlpha;
			viewFactory.mrtgDirPath = dfltMrtgPathFlashView;
			viewFactory.sessionID = sessionID;
			viewFactory.atkIsoX = dfltAtkIsoX;
			viewFactory.atkIsoY = dfltAtkIsoY;
			this.viewFactory = viewFactory;
			var edgeRenderer:myEdgeRenderer = new myEdgeRenderer(this);
			edgeRenderer.rateThickness = dfltRateLine;
			edgeRenderer.showAttack = dfltShowAttack;
			edgeRenderer.showRate = dfltShowRate;
			edgeRenderer.showRateInfo = dfltShowRateInfo;			
			this.edgeRenderer = edgeRenderer;
			this.mrtgDirPath = dfltMrtgPathFlashView;
			genTopologyData();
		}
		
		/*overrided by roamer*/
		override protected function doSaveConfig():void
		{
			configXml.dfltCenterID.@value = currentIDLog;
			configXml.showBG.@value = showBGLog;
			configXml.showStatus.@value = showStatusLog;
			configXml.showRate.@value = showRateLog;
			configXml.showRateInfo.@value = showRateInfoLog;			
			configXml.showAttack.@value = showAttackLog;
			configXml.identify.@value = txtLog;
			configXml.distance.@value = distanceLog;
			configXml.maxNode.@value = nodeLog;
			configXml.manual.@value = manualLog;
			configXml.alpha.@value = alphaLog;
			configXml.fontSize.@value = fontSizeLog;
			configXml.devFontColor.@value = (myViewFactory)(this.viewFactory).txtFontColor;
			configXml.rateFontColor.@value = this.txtFontColor;
			configXml.rateLine.@value = rateLineLog;
			configXml.scale.@value = scaleLog;
			configXml.hideVlan.@value = hideVlanLog;
			configXml.hideGroup.@value = hideGroupLog;
			configXml.hideLine.@value = hideLineLog;
			configXml.sndMenu.@Bad=sndIdx["Bad"];
			configXml.sndMenu.@Alarm=sndIdx["Alarm"];
			configXml.sndMenu.@Victim=sndIdx["Victim"];
			
			if(this.backGroundPicMoveEbl != 0)
			{
				configXml.backGroundPicX.@value=this.backGroundPicX.toString();
				configXml.backGroundPicY.@value=this.backGroundPicY.toString();
			}
			
			urSaveConfig.url =  dfltPHPDIR + saveCfgPHPName;
			urSaveConfig.method = URLRequestMethod.POST;
			urSaveConfig.requestHeaders.push(header);
			urSaveConfig.data = new URLVariables("newConfig="+configXml.toString()+"&fileName="+"dfltConfig" + roamerIdx + ".xml"+"&time="+Number(new Date().getTime()));
			loaderSaveConfig = new URLLoader();
			loaderSaveConfig.load(urSaveConfig);
		}
		
		public function genTopologyData(): void {
			urTreeParser.url =  dfltPHPDIR + "treeParser.php";
			urTreeParser.method = URLRequestMethod.GET;
			urTreeParser.requestHeaders.push(header);
			urTreeParser.data = new URLVariables("treepath="+dfltTreePath+"&mrtgpath="+dfltMrtgPathPHPView+"&output=tree"+roamerIdx+".xml"+"&encoding="+dfltEncoding+"&time="+Number(new Date().getTime()));
			loaderTreeParser = new URLLoader();
			loaderTreeParser.load(urTreeParser);
			loaderTreeParser.addEventListener(Event.COMPLETE, loadTopologyData);
		}	
		
		private function loadTopologyData(ev:Event):void
		{
			var resultStr:String = loaderTreeParser.data;
			
						
			if(resultStr.substr(0,8) == "Complete")
			{
				urTreeXML.url = dfltPHPDIR + "tree"+roamerIdx+".xml"
				urTreeXML.method = URLRequestMethod.GET;
				urTreeXML.requestHeaders.push(header);
				urTreeXML.data = new URLVariables("time="+Number(new Date().getTime()));
				ulTreeXML = new URLLoader();
				ulTreeXML.dataFormat = URLLoaderDataFormat.BINARY;
				ulTreeXML.load(urTreeXML);
				ulTreeXML.addEventListener(Event.COMPLETE, genLineData);
			}
			
			loaderTreeParser.close();
		}
		
		public function genLineData(ev:Event):void
		{
			var textTmp:String = ulTreeXML.data.readMultiByte(ulTreeXML.data.length, lang);
			treeXml =  new XML(textTmp);
			ulTreeXML.close();
			urTreeParser.url =  dfltPHPDIR + "lineParser.php";
			urTreeParser.method = URLRequestMethod.GET;
			urTreeParser.requestHeaders.push(header);
			urTreeParser.data = new URLVariables("linepath="+dfltLinePath+"&mrtgpath="+dfltMrtgPathPHPView+"&output=line"+roamerIdx+".xml"+"&encoding="+dfltEncoding+"&time="+Number(new Date().getTime()));
			loaderTreeParser = new URLLoader();
			loaderTreeParser.load(urTreeParser);
			loaderTreeParser.addEventListener(Event.COMPLETE, loadLineData);
		}	
		
		private function loadLineData(ev:Event):void
		{
			var resultStr:String = loaderTreeParser.data;
			if(resultStr.substr(0,8) == "Complete")
			{
				urTreeXML.url = dfltPHPDIR + "line"+roamerIdx+".xml"
				urTreeXML.method = URLRequestMethod.GET;
				urTreeXML.requestHeaders.push(header);
				urTreeXML.data = new URLVariables("time="+Number(new Date().getTime()));
				ulTreeXML = new URLLoader();
				ulTreeXML.load(urTreeXML);
				ulTreeXML.addEventListener(Event.COMPLETE, loadLocation);
			}
			loaderTreeParser.close();
		}
		
		public function loadLocation(ev:Event):void
		{
			var nodes: Array;
			
			lineXml =  new XML(ulTreeXML.data);

			
			fullGraphWithVlan = new Graph();
			fullGraphWithVlan.updateFromXML(treeXml, lineXml, null, rmVlan, rmGroup, rmLine, dfltCenterID);
			/*
			fullGraphRmVlan = new Graph();
			fullGraphRmVlan.updateFromXMLRmVlan(treeXml, null);
			*/
			ulTreeXML.close();
			
			urLoad.url =  dfltPHPDIR + this.locationFileName;
			urLoad.method = URLRequestMethod.GET;
			urLoad.requestHeaders.push(header);
			urLoad.data = new URLVariables("time="+Number(new Date().getTime()));
			loaderLoad = new URLLoader();
			loaderLoad.load(urLoad);
			loaderLoad.addEventListener(Event.COMPLETE, setLocation);
		}
		
		private function setLocation(ev:Event):void
		{
			var itemTmp : Item;
			var graphTmp: Graph;
			
			graphTmp = fullGraphWithVlan;
				
			
			if(loaderLoad.data != "")
			{
				locationXml =  new XML(loaderLoad.data);
				for each (var location: XML in locationXml.descendants("location")) {
					itemTmp = graphTmp.find(location.@id);
					if(itemTmp != null)
					{
						itemTmp.X = location.@x;
						itemTmp.Y = location.@y;
					}

					if(location.@id == "infoWinMrtg")
					{
						infoWinMrtgX = location.@x;
						infoWinMrtgY = location.@y;
						
						if(infoWinMrtg != null)
						{
							infoWinMrtg.x = infoWinMrtgX;
							infoWinMrtg.y = infoWinMrtgY;

						}

						
					}
					else if(location.@id == "infoWinDev")
					{
						infoWinDevX = location.@x;
						infoWinDevY = location.@y;
						
						if(infoWinDev != null)
						{
							infoWinDev.x = infoWinDevX;
							infoWinDev.y = infoWinDevY;
						}
					}
					
				}
			}
			
			this.dataProvider = fullGraphWithVlan;
						
			loadSnd();
			
		}
		private var urSndConfig:URLRequest = new URLRequest();
		private var loaderSnd:URLLoader;
		private var sndPath:Object;
		private var dfltSndPath:String =dfltPHPDIR+"Snd/"
		private var sndToPlay:String = "";
		
		public function loadSnd(): void{
		//		Alert.show("load Snd..................");
			dfltSndPath     =dfltPHPDIR+"Snd/";
			urSndConfig=new URLRequest();
			urSndConfig.url =  dfltSndPath + "sndFiles.xml";
			urSndConfig.method = URLRequestMethod.GET;
			urSndConfig.requestHeaders.push(header);
			urSndConfig.data = new URLVariables("time="+Number(new Date().getTime()));
			loaderSnd = new URLLoader();
			loaderSnd.addEventListener(Event.COMPLETE, setSnd);
			loaderSnd.load(urSndConfig);
			//	Alert.show("load Snd End");
			
		}
		
		private var loaderSnd2 = new URLLoader();
		private function setSnd(ev:Event):void{
		//		Alert.show("setSnd");
			var resXml:XML=new XML(loaderSnd.data);
			
			parseSndPath(resXml);
	/*		
			urSndConfig=new URLRequest();
			urSndConfig.url =  dfltSndPath + "sndSelected.sav";
			urSndConfig.method = URLRequestMethod.GET;
			urSndConfig.requestHeaders.push(header);
		//	urSndConfig.data = new URLVariables("time="+Number(new Date().getTime()));
			
			loaderSnd2.load(urSndConfig);
			loaderSnd2.addEventListener(Event.COMPLETE, setSelectedSnd);*/
		}
		
		private function parseSndPath(xml:XML):void{
			sndPath=new Object();
		//		Alert.show("Alert Message1..................");
			for each(var file:XML in xml.descendants("file")){
				sndPath[file.@idx]=file.@filename;
			}
			loadMenuBar();
		//		Alert.show("Alert Message2..................");
		}
		/*
		private function setSelectedSnd(ev:Event):void{
			var resString:String=String(loaderSnd2.data);
			parseSndConfig(resString);
			loadMenuBar();
		}
		
		
		private function parseSndConfig(conf:String):void{
			//	Alert.show("Parse Snd Config");
			var line:String;
			sndIdx= {Bad:"",Alarm:"",Victim:""};
			for each(line in conf.split("\n")){
				var args:Array=line.split("\t");
				sndIdx[args[0]]=args[1];
			}
			//	Alert.show("Parse Snd Config End"+sndIdx["Victim"]);
		}
		*/
		
		private var loaderSndToPlay:URLLoader=new URLLoader();
		public function checkAndPlaySnd():void{
			var urleq:URLRequest=new URLRequest();
			urleq.url =  dfltSndPath + "sndToPlay.php";
			urleq.method = URLRequestMethod.GET;
			urleq.requestHeaders.push(header);
			urleq.data = new URLVariables("Bad="+sndIdx["Bad"]+"&Alarm="+sndIdx["Alarm"]+"&Victim="+sndIdx["Victim"]);
			
			loaderSndToPlay = new URLLoader();
			loaderSndToPlay.load(urleq);
			loaderSndToPlay.addEventListener(Event.COMPLETE,playSnd);
			//	Alert.show("Check and play snd end");
		}
		public function playSnd(ev:Event):void{
		//		Alert.show("Start Play Snd");
			SoundMixer.stopAll();
			sndToPlay=String(loaderSndToPlay.data);
			if (sndToPlay!=""){
			//	Alert.show(String(new Date().toLocaleString())+"\nStatus abnormal?�\n"+"Status: "+sndToPlay);
				var ureq:URLRequest=new URLRequest();
				ureq.url=dfltSndPath+sndToPlay;
				ureq.requestHeaders.push(header);
				var snd:Sound = new Sound(ureq);
				snd.play(0, 1);
			}
			//	Alert.show('PlaySndEnd');
			
		}
		/*
		var loaderSaveSnd:URLLoader = new URLLoader();
		public function doSaveSndConfig():void
		{
			//		Alert.show('Saving Sound Configs~~~~~~~~~~~');
			//		Alert.show(menuBarXml);
			var alarmLabel:String=sndIdx["Alarm"];
			var badLabel:String=sndIdx["Bad"];
			var victimLabel:String=sndIdx["Victim"];
			
			var ureq=new URLRequest();
			ureq.url =  dfltPHPDIR + "Snd/saveSndConf.php";
			ureq.method = URLRequestMethod.GET;
			ureq.requestHeaders.push(header);
			ureq.data = new URLVariables("Alarm="+alarmLabel+"&Bad="+badLabel+"&Victim="+victimLabel);
			loaderSaveSnd=new URLLoader();
			loaderSaveSnd.load(ureq);
			loaderSaveSnd.addEventListener(Event.COMPLETE,saveSndComplete);
			
			
		}
		
		private function saveSndComplete(ev:Event):void{
			//Alert.show("SndSaveOk~");
			loaderSaveSnd.close();
		//	loadSnd();
		}*/
		
		private function loadMenuBar():void
		{
			urMenuBarXML.url = dfltPHPDIR +"menuBar" + lang + ".xml";
			trace("menu url " + urMenuBarXML.url);
			urMenuBarXML.method = URLRequestMethod.GET;
			urMenuBarXML.requestHeaders.push(header);
			urMenuBarXML.data = new URLVariables("time="+Number(new Date().getTime()));
			ulMenuBarXML = new URLLoader();
			ulMenuBarXML.load(urMenuBarXML);
			ulMenuBarXML.addEventListener(Event.COMPLETE, setMenuBar);
		}
		
		public var canSave:Boolean = false;
		public var sessionID:String = "";
		
		private function setMenuBar(ev:Event):void
		{	
			//Alert.show("setMenuBar");
			menuXml = new XML(ulMenuBarXML.data);
			
			var myParent:Object;
			myParent = this.parent;
			myParent.parent.changePanel(menuXml);
			
			delete menuXml.panelItem;
			
			if(fullGraphWithVlan != null)
			{
				//Alert.show("fullGraphWithVlan");
				delete menuXml.menuitem[0].*;
				
				var i:int = 0;
				var group:int = -1;
				var found:Boolean = false;
			//	Alert.show(fullGraphWithVlan.baseNodeArray.length.toString());
				if (fullGraphWithVlan.baseNodeArray.length>0){
					for each (var item: Item in fullGraphWithVlan.baseNodeArray) 
					{	//Alert.show("iter baseNodes");
						if((i % 10) == 0)
						{
							menuXml.menuitem[0].appendChild(<menuitem/>);
							group ++;
							menuXml.menuitem[0].menuitem[group].@label = menuXml.menuitem[0].@label + " " + group*10 + "-";
						}
						menuXml.menuitem[0].menuitem[group].appendChild(<menuitem/>);
						menuXml.menuitem[0].menuitem[group].menuitem[i%10].@label = item.data.@nodeType+" "+item.data.@ip+" "+item.data.@name;
						menuXml.menuitem[0].menuitem[group].menuitem[i%10].@data = "network_"+item.data.@id;
						menuXml.menuitem[0].menuitem[group].menuitem[i%10].@type = "radio";
						menuXml.menuitem[0].menuitem[group].menuitem[i%10].@groupName = "network";
						if(dfltCenterID == item.id)
						{
							menuXml.menuitem[0].menuitem[group].menuitem[i%10].@toggled = "true";
							found = true;
							updateCurrentItem(dfltCenterID);
						}
						menuXml.menuitem[0].menuitem[group].menuitem[i%10].@id = item.id;
						if((i % 10) == 9)
						{
							menuXml.menuitem[0].menuitem[group].@label = menuXml.menuitem[0].menuitem[group].@label + i;
						}
						i ++;
					}
					if(found == false)
						menuXml.menuitem[0].menuitem[0].menuitem[0].@toggled = "true";
					if((i % 10) != 0)
					{
						menuXml.menuitem[0].menuitem[group].@label = menuXml.menuitem[0].menuitem[group].@label + i;
					}
				}
			}
		//	Alert.show("SetMenuItemToggled");
			if(dfltShowBG == true)
				menuXml.menuitem[1].menuitem[0].@toggled = "true";
			else
				menuXml.menuitem[1].menuitem[0].@toggled = "false";
			
			if(dfltShowRate == true)
				menuXml.menuitem[1].menuitem[1].@toggled = "true";
			else
				menuXml.menuitem[1].menuitem[1].@toggled = "false";
			
			if(dfltShowRateInfo == true)
				menuXml.menuitem[1].menuitem[2].@toggled = "true";
			else
				menuXml.menuitem[1].menuitem[2].@toggled = "false";
			
			if(dfltShowAttack == true)
				menuXml.menuitem[1].menuitem[3].@toggled = "true";
			else
				menuXml.menuitem[1].menuitem[3].@toggled = "false";
			
			if(dfltShowStatus == true)
				menuXml.menuitem[1].menuitem[4].@toggled = "true";
			else
				menuXml.menuitem[1].menuitem[4].@toggled = "false";
			
			for each (var colorXml: XML in menuXml.menuitem[1].menuitem[5].descendants("menuitem"))
			{
				if((int)(colorXml.@data) == dfltDevFontColor)
					colorXml.@toggled = "true";
				else
					colorXml.@toggled = "false";
			}
			
			for each (var colorXml: XML in menuXml.menuitem[1].menuitem[6].descendants("menuitem"))
			{
				if((int)(colorXml.@data) == dfltRateFontColor)
					colorXml.@toggled = "true";
				else
					colorXml.@toggled = "false";
			}
			
			if(dfltIdentify == "ip")
			{
				menuXml.menuitem[1].menuitem[7].menuitem[0].@toggled = "true";
				menuXml.menuitem[1].menuitem[7].menuitem[1].@toggled = "false";
			}
			else
			{
				menuXml.menuitem[1].menuitem[7].menuitem[0].@toggled = "false";
				menuXml.menuitem[1].menuitem[7].menuitem[1].@toggled = "true";
			}
			
			if(dfltHideVlan == true)
				menuXml.menuitem[1].menuitem[8].@toggled = "true";
			else
				menuXml.menuitem[1].menuitem[8].@toggled = "false";
			
			if(dfltHideGroup == true)
				menuXml.menuitem[1].menuitem[9].@toggled = "true";
			else
				menuXml.menuitem[1].menuitem[9].@toggled = "false";
			
			if(dfltHideLine == true)
				menuXml.menuitem[1].menuitem[10].@toggled = "true";
			else
				menuXml.menuitem[1].menuitem[10].@toggled = "false";
			
			for each (var distanceXml: XML in menuXml.menuitem[2].menuitem[0].descendants("menuitem"))
			{
				if(distanceXml.@label == String(dfltDistance))
					distanceXml.@toggled = "true";
				else
					distanceXml.@toggled = "false";
			}
			
			for each (var maxNodeXml: XML in menuXml.menuitem[2].menuitem[1].descendants("menuitem"))
			{
				if(maxNodeXml.@label == String(dfltMaxNode))
					maxNodeXml.@toggled = "true";
				else
					maxNodeXml.@toggled = "false";
			}

			/*-------------Begin modified for Sound Menu--------------*/
		//	Alert.show("setSndMenu");
			for each (var menuItem:XML in menuXml.menuitem[3].menuitem)
			{
			//	Alert.show(menuItem.@label);
			//	Alert.show(menuItem.@name);
			//	if ("Bad" in sndIdx)
			//		Alert.show("Bad In sndIdx");
			//	else
			//		Alert.show("Bad not in sndIdx");
			//	Alert.show("SndIdx Bad "+sndIdx["Bad"]);
			//	Alert.show("SndIdx Alarm  "+sndIdx["Alarm"]);
			//	Alert.show("SndIdx Victim  "+sndIdx["Victim"]);

				if ((menuItem.@name=="Bad")){
					for each (var radioItem:XML in menuItem.menuitem){
						if (radioItem.@label==sndIdx["Bad"]){
							radioItem.@toggled=true;
							break;
						}
					}
				}
				else if ((menuItem.@name=="Alarm")){
					for each (var radioItem:XML in menuItem.menuitem){
						if (radioItem.@label==sndIdx["Alarm"]){
							radioItem.@toggled=true;
							break;
						}
					}
				}
				else if ((menuItem.@name=="Victim")){
					for each (var radioItem:XML in menuItem.menuitem){
						if (radioItem.@label==sndIdx["Victim"]){
							radioItem.@toggled=true;
							break;
						}
					}
				}
	
			}
	//		Alert.show("setUILocation");
			/*-------------End modified for Sound menu----------------*/
			this.setUI(menuXml, dfltManual, dfltShowRate, dfltShowAttack, dfltShowStatus, dfltAlpha, dfltFontSize, dfltRateLine, canSave);
			this.updateUILocation(dfltSaveButtonX, dfltSaveButtonY, dfltManualButtonX, dfltManualButtonY);
						
			
			ulMenuBarXML.close();
			//Alert.show("setMenuBar OK");
		//	checkAndPlaySnd();
	//		Alert.show("setMenuBar OK");
			//loadRedirect();
			/*refreshAttack();
			refresStatus();*/
		}
		
		public function loadRedirect():void
		{
			//Alert.show("loadRedirect");
			
			urRedirect.url = dfltPHPDIR + "redirectProxy.php";
			urRedirect.method = URLRequestMethod.GET;
			urRedirect.requestHeaders.push(header);
			
			if(sessionID != null)
			{
				urRedirect.data = new URLVariables("redirectpath="+dfltRedirectPath+sessionID+".redirect.txt"+"&time="+Number(new Date().getTime()));
				//Alert.show("redirectpath="+dfltRedirectPath+sessionID+".redirect.txt"+"&time="+Number(new Date().getTime()));
			}
			else
			{
				urRedirect.data = new URLVariables("redirectpath="+dfltRedirectPath+"redirect.txt"+"&time="+Number(new Date().getTime()));
				//Alert.show("redirectpath="+dfltRedirectPath+"redirect.txt"+"&time="+Number(new Date().getTime()));
			}
			
			//urRedirect.data = new URLVariables("redirectpath="+dfltRedirectPath+"&time="+Number(new Date().getTime()));
			loaderRedirect = new URLLoader();
			loaderRedirect.load(urRedirect);
			loaderRedirect.addEventListener(Event.COMPLETE, setRedirect);	
			
		}
	
		private function setRedirect(ev:Event):void
		{					
			//var redirectItem:Item = null;
			//Alert.show(loaderRedirect.data);
			var redirectItemArray:Array = null;
			var lines:Array = String(loaderRedirect.data).split("\n");
			var words:Array;
			var urlString:String;
			var patern:RegExp = new RegExp("\\(redirect.\\d+\\)");
			var numPatern:RegExp = new RegExp("\\d+");
			
			for each (var devXML: XML in clickEventXml.descendants("doubleClick").descendants("dev")) 
			{
				devXML.@DevIconUrlIdx = "-1";
				devXML.@StatusIconUrlIdx = "-1";
				devXML.@attackUrlIdx = "-1";
				
				if("Edge" == devXML.@type)
				{
					if(String(devXML.@EdgeUrl).length != 0)
					{
						this.edgeUrlFmt = devXML.@EdgeUrl; 
					}
				}
				
				if(String(devXML.@DevIconUrl).length != 0)
				{
					urlString = devXML.@DevIconUrl;
					if(urlString.search(patern) != -1)
					{
						var urlIdx:int = ((String)(urlString.match(patern))).match(numPatern);
						devXML.@DevIconUrlIdx = urlIdx.toString();
					}
				}
				if(String(devXML.@StatusIconUrl).length != 0)
				{
					urlString = devXML.@StatusIconUrl;
					if(urlString.search(patern) != -1)
					{
						var urlIdx:int = ((String)(urlString.match(patern))).match(numPatern);
						devXML.@StatusIconUrlIdx = urlIdx.toString();
					}
				}
				if(String(devXML.@attackUrl).length != 0)
				{
					urlString = devXML.@attackUrl;
					if(urlString.search(patern) != -1)
					{
						var urlIdx:int = ((String)(urlString.match(patern))).match(numPatern);
						devXML.@attackUrlIdx = urlIdx.toString();
					}
				}
			}
			
			for each (var line: String in lines) {

				words = line.split("\t");
				
				if(words[0] == "ip")
					redirectItemArray = super.dataProvider.findItemArrayByIP(words[1]);
				else if(words[0] == "idx")
					redirectItemArray = super.dataProvider.findItemArrayByIdx(words[1]);
				else if(words[0] == "name")
				{
					redirectItemArray = super.dataProvider.findItemArrayByName(words[1]);
				}
				else 
					redirectItemArray = null;
				if(redirectItemArray!=null)
				{
					for each (var redirectItem:Item in redirectItemArray)
					{
						redirectItem.redirectWords = words;
						for each (var devXML: XML in clickEventXml.descendants("doubleClick").descendants("dev")) 
						{
							if(((String(devXML.@ip).length == 0) && (redirectItem.data.@nodeType == devXML.@type)) ||
								((String(devXML.@ip).length != 0) && (redirectItem.data.@ip == devXML.@ip) && (redirectItem.data.@nodeType == devXML.@type)))
							{
								var idx:int;
								idx = devXML.@DevIconUrlIdx;
																
								if((idx != -1) && (words.length >= idx+3))
									redirectItem.devPath = words[idx+2];
								else
									redirectItem.devPath = "none";

								idx = devXML.@StatusIconUrlIdx;
								if((idx != -1) && (words.length >= idx+3))
									redirectItem.statePath = words[idx+2];
								else
									redirectItem.statePath = "none";
								idx = devXML.@attackUrlIdx;
								if((idx != -1) && (words.length >= idx+3))
									redirectItem.atkLinkPath = words[idx+2];
								else
									redirectItem.atkLinkPath = "none";
							}
						}
					}
				}
				
				/*
				if(words[0] == "ip")
					redirectItemArray = fullGraphRmVlan.findItemArrayByIP(words[1]);
				else if(words[0] == "idx")
					redirectItemArray = fullGraphRmVlan.findItemArrayByIdx(words[1]);
				else if(words[0] == "name")
				{
					redirectItemArray = fullGraphRmVlan.findItemArrayByName(words[1].toString());
				}
				else 
					redirectItemArray = null;
				
				if(redirectItemArray!=null)
				{ 
					for each (var redirectItem:Item in redirectItemArray)
					{
						redirectItem.redirectWords = words;
						for each (var devXML: XML in clickEventXml.descendants("doubleClick").descendants("dev")) 
						{
							if(((String(devXML.@ip).length == 0) && (redirectItem.data.@nodeType == devXML.@type)) ||
								((String(devXML.@ip).length != 0) && (redirectItem.data.@ip == devXML.@ip) && (redirectItem.data.@nodeType == devXML.@type)))
							{
								var idx:int;
								idx = devXML.@DevIconUrlIdx;
								if((idx != -1) && (words.length >= idx+3))
									redirectItem.devPath = words[idx+2];
								else
									redirectItem.devPath = "none";
								idx = devXML.@StatusIconUrlIdx;
								if((idx != -1) && (words.length >= idx+3))
									redirectItem.statePath = words[idx+2];
								else
									redirectItem.statePath = "none";
								idx = devXML.@attackUrlIdx;
								if((idx != -1) && (words.length >= idx+3))
									redirectItem.atkLinkPath = words[idx+2];
								else
									redirectItem.atkLinkPath = "none";
							}
						}
					}
				}
				*/
			}

			loaderRedirect.close();
			refreshAttack();
			refresStatus();
			
		}
		
		public function refreshAttack():void
		{
			//Alert.show("refreshAttack");
			urAttack.url = dfltPHPDIR + "atkProxy.php";
			urAttack.method = URLRequestMethod.GET;
			urAttack.requestHeaders.push(header);
			urAttack.data = new URLVariables("atkpath="+dfltAtkPath+"&time="+Number(new Date().getTime()));
			loaderAttack = new URLLoader();
			loaderAttack.load(urAttack);
			loaderAttack.addEventListener(Event.COMPLETE, parseAttack);
		}
		
		private function parseAttack(ev:Event):void
		{
			var isSrc:Boolean;
			var isVictim:Boolean;
			var attackSrcItem:Item = null;
			var atkSrcArrayA: Object = new Object();
			var atkSrcArrayB: Object = new Object();
			var attackVictimItem:Item = null;
			
			attackXml =  new XML(loaderAttack.data);
									
			this.clearAttack();
			
			for each (var attackSrc: XML in attackXml.descendants("ATTACK_SRC")) {
				attackSrcItem = super.dataProvider.findByIP(attackSrc.@ip);
				//Alert.show("find source "+ attackSrc.@ip + " result " + (attackSrcItem==null).toString());
				if(attackSrcItem!=null)
				{
					attackSrcItem.attackSrcID = attackSrc.@id;
					atkSrcArrayA[attackSrc.@id] = attackSrcItem;
					attackSrcItem.atkXML = attackSrc;
				}
				
				/*
				attackSrcItem = fullGraphRmVlan.findByIP(attackSrc.@ip);
				if(attackSrcItem!=null)
				{
					attackSrcItem.attackSrcID = attackSrc.@id;
					atkSrcArrayB[attackSrc.@id] = attackSrcItem;
					attackSrcItem.atkXML = attackSrc;
				}
				*/
			}
			
			for each (var attackVictim: XML in attackXml.descendants("ATTACK_VICTIM")) {
				
				attackVictimItem = super.dataProvider.findByIP(attackVictim.@ip);
				//Alert.show("find victim "+ attackVictim.@ip + " result " + (attackVictimItem==null).toString());
				if(attackVictimItem!=null)
				{
					attackVictimItem.attackVictimID = attackVictim.@id;
					if(atkSrcArrayA.hasOwnProperty(attackVictim.@id))
					{
						super.dataProvider.setAttackPath(atkSrcArrayA[attackVictim.@id], attackVictimItem, attackVictim.@id, rmVlan, rmGroup);
					}
					attackVictimItem.atkXML = attackVictim;
				}
				
				/*
				attackVictimItem = fullGraphRmVlan.findByIP(attackVictim.@ip);
				
				if(attackVictimItem!=null)
				{
					attackVictimItem.attackVictimID = attackVictim.@id;
					if(atkSrcArrayB.hasOwnProperty(attackVictim.@id))
					{
						fullGraphRmVlan.setAttackPathRmVlan(atkSrcArrayB[attackVictim.@id], attackVictimItem, attackVictim.@id);
					}
					attackVictimItem.atkXML = attackVictim;
				}
				*/
			}
			
			for each (var attackIsoSrc: XML in attackXml.descendants("ATTACK_ISO_SRC")) {
				attackSrcItem = super.dataProvider.findByIP(attackIsoSrc.@ip);
				if(attackSrcItem!=null)
				{
					attackSrcItem.attackSrcID = -1;
					attackSrcItem.atkXML = attackIsoSrc;
				}
				
				/*
				attackSrcItem = fullGraphRmVlan.findByIP(attackIsoSrc.@ip);
				if(attackSrcItem!=null)
				{
					attackSrcItem.attackSrcID = -1;
					attackSrcItem.atkXML = attackIsoSrc;
				}
				*/
			}
			
			this.reDrawAttack();
			loaderAttack.close();
		}
		
		public function refresStatus():void
		{
			urStatus.url = dfltPHPDIR + "statusProxy.php";
			urStatus.method = URLRequestMethod.GET;
			urStatus.requestHeaders.push(header);
			urStatus.data = new URLVariables("statuspath="+dfltStatusPath+"&time="+Number(new Date().getTime()));
			loaderStatus = new URLLoader();
			loaderStatus.load(urStatus);
			loaderStatus.addEventListener(Event.COMPLETE, parseStatus);
		}
		
		private function parseStatus(ev:Event):void
		{					
			var statusItem:Item = null;
			var lines:Array = String(loaderStatus.data).split("\n");
			var words:Array;
			
			//Alert.show("refreshStatus");
			
			this.clearStatus();
			
			for each (var line: String in lines) {
				
				words = line.split(",");
				if(words[2] == "name")
					statusItem = super.dataProvider.findByName(words[0]);
				else
					statusItem = super.dataProvider.findByIP(words[0]);
				if(statusItem!=null)
				{
					statusItem.status = words[1];
				}
								
				/*
				statusItem = fullGraphRmVlan.findByIP(words[0]);
				if(statusItem!=null)
				{
					statusItem.status = words[1];
				}
				*/
			}
			
			this.reDrawStatus();
			
			loaderStatus.close();
			checkAndPlaySnd();
		}
		
		public function refreshRate():void
		{
			
			urTreeParser.url =  dfltPHPDIR + "treeParser.php";
			urTreeParser.method = URLRequestMethod.GET;
			urTreeParser.requestHeaders.push(header);
			urTreeParser.data = new URLVariables("treepath="+dfltTreePath+"&mrtgpath="+dfltMrtgPathPHPView+"&output=tree"+roamerIdx+".xml"+"&encoding="+dfltEncoding+"&time="+Number(new Date().getTime()));
			loaderTreeParser = new URLLoader();
			loaderTreeParser.load(urTreeParser);
			loaderTreeParser.addEventListener(Event.COMPLETE, loadRate);
		}
		
		private function loadRate(ev:Event):void
		{
			var resultStr:String = loaderTreeParser.data;

			if(resultStr.substr(0,8) == "Complete")
			{
				urTreeXML.method = URLRequestMethod.GET;
				urTreeXML.requestHeaders.push(header);
				urTreeXML.url = dfltPHPDIR + "tree"+roamerIdx+".xml";
				urTreeXML.data = new URLVariables("time="+Number(new Date().getTime()));
				ulTreeXML = new URLLoader();
				ulTreeXML.dataFormat = URLLoaderDataFormat.BINARY;
				ulTreeXML.load(urTreeXML);
				ulTreeXML.addEventListener(Event.COMPLETE, refreshLine);
			}
		
			loaderTreeParser.close();
		}
		
		public function refreshLine(ev:Event):void
		{
			var textTmp:String = ulTreeXML.data.readMultiByte(ulTreeXML.data.length, lang);
			treeXml =  new XML(textTmp);
			ulTreeXML.close();
			urTreeParser.url =  dfltPHPDIR + "lineParser.php";
			urTreeParser.method = URLRequestMethod.GET;
			urTreeParser.requestHeaders.push(header);
			urTreeParser.data = new URLVariables("linepath="+dfltLinePath+"&mrtgpath="+dfltMrtgPathPHPView+"&output=line"+roamerIdx+".xml"+"&encoding="+dfltEncoding+"&time="+Number(new Date().getTime()));
			loaderTreeParser = new URLLoader();
			loaderTreeParser.load(urTreeParser);
			loaderTreeParser.addEventListener(Event.COMPLETE, loadLine);
		}	
		
		private function loadLine(ev:Event):void
		{
			var resultStr:String = loaderTreeParser.data;
			if(resultStr.substr(0,8) == "Complete")
			{
				urTreeXML.url = dfltPHPDIR + "line"+roamerIdx+".xml"
				urTreeXML.method = URLRequestMethod.GET;
				urTreeXML.requestHeaders.push(header);
				urTreeXML.data = new URLVariables("time="+Number(new Date().getTime()));
				ulTreeXML = new URLLoader();
				ulTreeXML.dataFormat = URLLoaderDataFormat.BINARY;
				ulTreeXML.load(urTreeXML);
				ulTreeXML.addEventListener(Event.COMPLETE, updateRate);
			}
			loaderTreeParser.close();
		}
		
		private function updateRate(ev:Event):void
		{
			var textTmp:String = ulTreeXML.data.readMultiByte(ulTreeXML.data.length, lang);
			var nodesTmp: Object;
			var itemTmp : Item;			
						
 			lineXml =  new XML(textTmp);

			doRecordLocation();
			locationXml = new XML(locationLog);

			//nodesTmp = fullGraphWithVlan.nodes();	

			//fullGraphWithVlan.updateFromXML(treeXml, lineXml, null, rmVlan, rmGroup, rmLine, _currentItem.id);
			//this.dataProvider.updateFromXML(treeXml, lineXml, null, rmVlan, rmGroup, rmLine, _currentItem.id);
			
			//doSetDataProvider(fullGraphWithVlan);
			
			//this.reDrawCurrent();
			//this.drawEdges();
			
			updateCurrentItem( _currentItem.id);

						
			/*
			var nodes: Array = _dataProvider.getAllNodes();
			
			for each (var node: Node in nodes) {
				if((GraphNode)(node).item.specialAlpha != 0)
					(GraphNode)(node).view.alpha = (GraphNode)(node).item.specialAlpha;
				else
					(GraphNode)(node).view.alpha = this.alphaLog;
			}
				*/		
			ulTreeXML.close();
					
		}
		
		
		///// -------- private ------------

		private function doSetDataProvider(g: Graph): void {
			empty();
			setFullGraph(g);
			dispatchEvent(new Event("dataProviderChange"));
		}
		
		private function setFullGraph(g: Graph): void {
			fullGraph = g;
			resetHistory();
			newCurrentItem(g.distinguishedItem);
			dispatchEvent(new Event("currentItemChange"));
			recreateGraph();
		}
	
		private function addNodes(newNodes: Array, g: Graph): Object {
			var newItems: Object = [];
			var item: Item;
			var i: int;
			var id: String;
			for (id in newNodes) {
				if(!g.hasNode(id)) {
					item = fullGraph.find(id);
					g.add(item);
					newItems[item.id] = item;
				}
			}
			for (id in newItems) {
				item = newItems[id] as Item;
				var neighbors: Object = fullGraph.neighbors(item.id);
				for(var neighborId: String in neighbors) {
					if(g.hasNode(neighborId)) {
						g.link(item, g.find(neighborId));
					}
				}
			}
			return newItems;
		}
		
		public function reDrawCurrent():void {
			recreateGraph();
		}
		
		private function recreateGraph(): void {
			var g: Graph = new Graph();
			
			if(_currentItem != null) {
				fullGraph.clearNumShowChild();
				itemCount = 0;
				
				addToGraph(_currentItem, 1, g);
			}
			
			_visibleHistoryItems = null;
			if(_showHistory) {
				_visibleHistoryItems = addNodes(allCurrentItems, g);
			}
			
			if(forceVisible != null) {
				addNodes(forceVisible, g);
			}
			
			if(forceInvisible != null) {
				for (var i: Number = 0; i < forceInvisible.length; i++) {
					var item: Item = forceInvisible[i] as Item;
					g.remove(item);
				}
			}
			if(_tidyHistory)
				doTidyHistory(_visibleHistoryItems, g);
			
			super.dataProvider = g;
			dispatchEvent(new Event("change"));
			dispatchEvent(new Event("visibleHistoryItemsChange"));
		}

		private static var historySeed: Item = new HistorySeed();
		
		private function doTidyHistory(addedItems: Object, g: Graph): void {
			if(addedItems == null) return;
			
			var historyItemAdded: Boolean = false;
			var historyItemLinks: int = 0;
			
			for (var id: String in addedItems) {
				var addedItem: Item = addedItems[id] as Item;
				var neighbors: Object = g.neighbors(id);
				var connectedToGraph: Boolean = false;
				for(var neighborID: String in neighbors) {
					if(!addedItems.hasOwnProperty(neighborID)) {
						connectedToGraph = true;
						break;
					}
				}

				if(!connectedToGraph) {
					if(!historyItemAdded) {
						g.add(historySeed);
						historyItemAdded = true;
					}
					g.link(addedItem, historySeed, {settings: {alpha: 0, color: 0x0000dd, thickness: 0}});
					historyItemLinks++;
				}
			}
			
			//if(historyItemAdded && (historyItemLinks < 2)) {
			//	g.remove(historySeed);
			//}
		}
		
		private function arrayIncludes(list: Object, item: Object): Boolean {
			var result: Boolean = list.hasOwnProperty(item.id);
			return result;
		}

		private function addToGraph(item: Item, generation: int, graph: Graph): Number {
			var data1:Object;
			var data2:Object;
			
			if(itemCount >= _itemLimit) return 0; //0 = stop
			if(graph.find(item.id) != null)
			{
				return 1; //1= skip and continue
			}
			itemCount ++;
			graph.add(item);
			if(_skipItem != null && item.id == _skipItem.id)
			{
				return 1; //1= skip and continue
			}


			if(item.parentItem != null)
			{
				item.parentItem.numShownChild ++;
			}
			
			
			var neighbors: Object = fullGraph.neighbors(item.id);
			for(var neighborId: String in neighbors) {
				var neighbor: Item = fullGraph.find(neighborId)
		
				if(neighbor.id.length/3 <= _maxDistanceFromCurrent) 
				{
					if(addToGraph(neighbor, neighbor.id.length/3, graph) == 0)
						return 2;  //2= success, go on
	
					data1 = fullGraph.getLinkData(item, neighbor);
					data2 = fullGraph.getLinkData(neighbor, item);
					
					graph.linkDoubleColor(item, neighbor, data1, data2);
				}
			}
			

			
			return 2; //2= success, go on
		}			
		
		private function newCurrentItem(item: Item): void {
			_currentItem = item;
			if(item != null) {
				allCurrentItems[item.id] = true;
				//if(historyCurrentlyViewed < (_history.length - 1)) {
				//	var temp: int = historyCurrentlyViewed + 1;
				//	_history.splice(temp);
				//}
				_history.push(item);
				historyCurrentlyViewed = _history.length - 1;
				dispatchEvent(new Event("historyChange"));
			}
		}

		private var _currentItem: Item;
		private var _skipItem: Item = null;
		private var _itemLimit: int = 50;
		public var fullGraphWithVlan: Graph;
		//public var fullGraphRmVlan: Graph;
		private var _maxDistanceFromCurrent: int;		
		private var itemCount: int;
		private var allCurrentItems: Array = new Array();
		private var _showHistory: Boolean = false;	
		private var _history: Array = new Array();
		private var historyCurrentlyViewed: int = -1;
		private var _visibleHistoryItems: Object = null;		
		private var _tidyHistory: Boolean = true;
		
	}
}
