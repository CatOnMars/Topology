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

package com.adobe.flex.extras.controls.springgraph
{
	import com.adobe.flex.extras.controls.springgraph.IViewFactory;
	import com.adobe.flex.extras.controls.springgraph.Item;
	import com.adobe.flex.extras.controls.springgraph.myItemView;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.xml.XMLNode;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	
	
	
	/** Defines an object that knows how to create views for Items. */
	public class myViewFactory implements IViewFactory
	{
		
		//protected var dfltPHPDIR:String = "http://localhost/";
		protected var dfltPHPDIR:String = "../";
		
		private var urURLCheck:URLRequest = new URLRequest();
		//private var loaderURLCheck:URLLoader;
		private var header:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
		
		[Embed(source='firewall.swf')]
		private var firewallPic:Class;
		
		[Embed(source='router.swf')]
		private var routerPic:Class;
		
		[Embed(source='switch.swf')]
		private var switchPic:Class;
		
		[Embed(source='dmz.swf')]
		private var dmzPic:Class;
		
		[Embed(source='vlan.swf')]
		private var vlanPic:Class;
		
		[Embed(source='ip.swf')]
		private var ipPic:Class;
		
		[Embed(source='host.swf')]
		private var hostPic:Class;
		
		[Embed(source='mfp.swf')]
		private var mfpPic:Class;
		
		[Embed(source='mobile.swf')]
		private var mobilePic:Class;
		
		[Embed(source='mvDevice.swf')]
		private var mvDevicePic:Class;
		
		[Embed(source='ncm.swf')]
		private var ncmPic:Class;
		
		[Embed(source='printer.swf')]
		private var printerPic:Class;
		
		
		[Embed(source='attackSrc.swf')]
		private var attackSrcPic:Class;
		
		[Embed(source='attackVictim.swf')]
		private var attackVictimPic:Class;
		
		[Embed(source='status1.swf')]
		private var status1Pic:Class;
		
		[Embed(source='status2.swf')]
		private var status2Pic:Class;
		
		[Embed(source='status3.swf')]
		private var status3Pic:Class;
		
		[Embed(source='status4.swf')]
		private var status4Pic:Class;
		
		[Embed(source='status5.swf')]
		private var status5Pic:Class;
		
		[Embed(source='cloud.swf')]
		private var cloudPic:Class;
		
		[Embed(source='Stack.swf')]
		private var stackPic:Class;
		
		[Embed(source='Group.swf')]
		private var groupPic:Class;
		
		[Embed(source='WLanController.swf')]
		private var wlanPic:Class;
		
		[Embed(source='AP.swf')]
		private var apPic:Class;

		[Embed(source='VM.swf')]
		private var vmPic:Class;
		
		[Embed(source='VT.swf')]
		private var vtPic:Class;
		
		[Embed(source='IPcamera.swf')]
		private var ipCamPic:Class;
		
		[Embed(source='IPphone.swf')]
		private var ipPhonePic:Class;
		
		[Embed(source='VMhost.swf')]
		private var vmhostPic:Class;
		
		[Embed(source='vSwitch.swf')]
		private var vswitchPic:Class;		
		
		public function setClickEventXML(clickXml: XML):void
		{
			clickEventXML = clickXml;
		}
		
		private function setClickEvent(itemView:myItemView, item:Item):void
		{	
			var urlString:String;
			var urlStringAll:String;
			var keyEmpty:Object = new Object();
			var myContextMenu : ContextMenu = new ContextMenu();
			myContextMenu.hideBuiltInItems();
			
			if(clickEventXML != null)
			{
				/*set RightClick menu*/
				itemView.menuURL = new Object();
				for each (var devXML: XML in clickEventXML.descendants("rightClickMenu").descendants("dev")) 
				{
					if(((String(devXML.@ip).length == 0) && (itemView.data.@nodeType == devXML.@type)) ||
						((String(devXML.@ip).length != 0) && (itemView.data.@ip == devXML.@ip) && (itemView.data.@nodeType == devXML.@type)))
					{
						urlStringAll = "";
						
						for each (var itemXML: XML in devXML.descendants("item"))
						{
							var GoUrlItem : ContextMenuItem = new ContextMenuItem(itemXML.@label);			
							GoUrlItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,GoUrl);
							if(itemXML.@enabled == "true")
								GoUrlItem.enabled = true;
							else
								GoUrlItem.enabled = false;
							urlString = transUrlString(itemView, item, itemXML.@url, keyEmpty);
							itemView.menuURL[itemXML.@label] = urlString;
							if(keyEmpty[0] == true)
							{
								GoUrlItem.enabled = false;
							}

							urlStringAll = urlStringAll + urlString + "<br>";
							myContextMenu.customItems.push(GoUrlItem);						
						}
						
						/* FIX ME
						var loaderURLCheck:URLLoader;
						
						urURLCheck.url = dfltPHPDIR + "urlCheck.php";	
						urURLCheck.method = URLRequestMethod.POST;
						urURLCheck.requestHeaders.push(header);
						urURLCheck.data = new URLVariables("urlAll="+urlStringAll+"&time="+Number(new Date().getTime()));
						loaderURLCheck = new URLLoader();
						loaderURLCheck.addEventListener(Event.COMPLETE, function(e:Event){urlCheck(e, itemView, loaderURLCheck)});
						loaderURLCheck.load(urURLCheck);
						*/
						break;
					}
				}
				
			}
			
			itemView.devPic.contextMenu = myContextMenu;
			itemView.devPic.buttonMode = true;
			myContextMenu.addEventListener(ContextMenuEvent.MENU_SELECT,TestRightClick);
		}
		
		private function TestRightClick(event:ContextMenuEvent):void{
			
			var urlStr:String = "";
			var itemView:myItemView =(myItemView)(((MovieClip)(event.contextMenuOwner)).parent)
	//		Alert.show(urlStr);
			for (var key:String in itemView.menuURL){
				urlStr+=(key+"\t"+itemView.menuURL[key]+"\n");
			}	
//			Alert.show(urlStr);
			
			var item:Item;
			item = (Roamer)(itemView.parent).fullGraphWithVlan.find(itemView.itemId);
//			if(!item.redirectWords)
//				Alert.show("redirectWords Null");
		}
		private function urlCheck(ev:Event, itemView:myItemView, loaderURLCheck:URLLoader):void
		{	
			//var urlXml:XML =  new XML(loaderURLCheck.data);
			trace(loaderURLCheck.data);
		}
		
		private function GoAtkUrl(event:ContextMenuEvent):void
		{
			var urlStr:String = "";
			var itemView:myItemView = (myItemView)(((MovieClip)(event.contextMenuOwner)).parent);
			
			navigateToURL(new URLRequest(itemView.menuURL[(ContextMenuItem)(event.currentTarget).caption+"_"+itemView.itemId]), "_blank");
		}
		
		private function GoUrl(event:ContextMenuEvent):void
		{
			
			var urlStr:String = "";
			var itemView:myItemView = (myItemView)(((MovieClip)(event.contextMenuOwner)).parent);
			//navigateToURL(new URLRequest(itemView.menuURL[(ContextMenuItem)(event.currentTarget).caption]), "_blank");
			urlStr = itemView.menuURL[event.currentTarget.caption];
		//	Alert.show(urlStr);
	/*		
			var patern:RegExp = new RegExp("\\(redirect.\\d+\\)");
			var numPatern:RegExp = new RegExp("\\d+");
			var item:Item;
			item = (Roamer)(itemView.parent).fullGraphWithVlan.find(itemView.itemId);
			if(item != null)
			{
				Alert.show("Item Not Null");
		//		if(!item.redirectWords)
			//		Alert.show("redirectWords Null");
				var testStr="";
				for(var i=0;i<item.redirectWords.length;++i){
					testStr+=(item.redirectWords[i]+'\n');
				}
				Alert.show(testStr);
				while(urlStr.search(patern) != -1)
				{
					var redirectIdx:int = ((String)(urlStr.match(patern))).match(numPatern);
					if(item.redirectWords != null && item.redirectWords.length >= redirectIdx+3){
						urlStr = urlStr.replace(patern, item.redirectWords[redirectIdx+2]);
						Alert.show("REDIRECT TO:"+item.redirectWords[redirectIdx+2]);
					}
					else
						urlStr = urlStr.replace(patern, "");	
				}
			}
			
		*/	
			if(urlStr != "")
			{
				navigateToURL(new URLRequest(urlStr), "_blank");
			}
		//	Alert.show(urlStr);
		}
		
		private function transUrlString(itemView:myItemView, item:Item, url:String, keyEmpty:Object):String
		{
			var urlString:String = new String(url);
			keyEmpty[0] = false;
			while(urlString.search("(mrtgPath)") != -1)
				urlString = urlString.replace("(mrtgPath)", mrtgDirPath);
			while(urlString.search("(ip)") != -1)
			{
				urlString = urlString.replace("(ip)", itemView.data.@ip);
				if(String(itemView.data.@ip).length == 0)
					keyEmpty[0] = true;
			}
			while(urlString.search("(idx)") != -1)
			{
				urlString = urlString.replace("(idx)", itemView.data.@idx);
				if(String(itemView.data.@idx).length == 0)
					keyEmpty[0] = true;
			}
			while(urlString.search("(id)") != -1)
			{
				urlString = urlString.replace("(id)", itemView.data.@id);
				if(String(itemView.data.@id).length == 0)
					keyEmpty[0] = true;
			}
			while(urlString.search("(nodeType)") != -1)
				urlString = urlString.replace("(nodeType)", itemView.data.@nodeType);
			while(urlString.search("(name)") != -1)
				urlString = urlString.replace("(name)", itemView.data.@name);
			while(urlString.search("(sessionID)") != -1)
				urlString = urlString.replace("(sessionID)", sessionID);
			
			var patern:RegExp = new RegExp("\\(redirect.\\d+\\)");
			var numPatern:RegExp = new RegExp("\\d+");
			if(urlString.search(patern) != -1)
			{
				var redirectIdx:int = ((String)(urlString.match(patern))).match(numPatern);
				if(item.redirectWords != null && item.redirectWords.length >= redirectIdx+3)
				{
					if(item.redirectWords[redirectIdx+2] != "" && item.redirectWords[redirectIdx+2] != "none")
						urlString = urlString.replace(patern, item.redirectWords[redirectIdx+2]);
						 // translate the string when connect to url
					else
					{
						urlString = urlString.replace(patern, "");
						keyEmpty[0] = true;
					}
				}
				else
				{
					urlString = urlString.replace(patern, "");
					keyEmpty[0] = true;
				}	
			}
			
			return urlString;
		}
		
		/** 
		 * Create a UIComponent to represent a given Item in a SpringGraph. The returned UIComponent should
		 * be a unique instance dedicated to that Item. This function might return a unique view component
		 * on each call, or it might cache views and return the same view if called repeatedly 
		 * for the same item. This function may return different classes of object based on the type
		 * or data of the Item.
		 * @param item an item for which y
		 * @return a unique UIComponent to represent the Item. This component must also implement the IDataRenderer interface.
		 * It's OK to return null.
		 * 
		 */
		public function getView(item: Item): UIComponent
		{
			var itemView:myItemView = new myItemView;
			
			if(item.data.@nodeType == "Router")
				itemView.devPic = new routerPic;
			else if(item.data.@nodeType == "Switch") 
				itemView.devPic = new switchPic;
			else if(item.data.@nodeType == "VLAN") 
				itemView.devPic = new vlanPic;
			else if(item.data.@nodeType == "Firewall") 
				itemView.devPic = new firewallPic;
			else if(item.data.@nodeType == "IP") 
				itemView.devPic = new ipPic;
			else if(item.data.@nodeType == "DMZ") 
				itemView.devPic = new dmzPic;
			else if(item.data.@nodeType == "Host") 
				itemView.devPic = new hostPic;
			else if(item.data.@nodeType == "Cloud") 
				itemView.devPic = new cloudPic;
			else if(item.data.@nodeType == "WLanController") 
				itemView.devPic = new wlanPic;
			else if(item.data.@nodeType == "AP") 
				itemView.devPic = new apPic;
			else if(item.data.@nodeType == "VM") 
				itemView.devPic = new vmPic;
			else if(item.data.@nodeType == "VT") 
				itemView.devPic = new vtPic;
			else if(item.data.@nodeType == "IPcamera") 
				itemView.devPic = new ipCamPic;
			else if(item.data.@nodeType == "IPphone") 
				itemView.devPic = new ipPhonePic;
			else if(item.data.@nodeType == "Stack") 
				itemView.devPic = new stackPic;
			else if(item.data.@nodeType == "Group") 
				itemView.devPic = new groupPic;
			else if(item.data.@nodeType == "VMhost") 
				itemView.devPic = new vmhostPic;
			else if(item.data.@nodeType == "vSwitch") 
				itemView.devPic = new vswitchPic;
			else if(item.data.@nodeType == "MFP") 
				itemView.devPic = new mfpPic;
			else if(item.data.@nodeType == "Mobile") 
				itemView.devPic = new mobilePic;
			else if(item.data.@nodeType == "MvDevice") 
				itemView.devPic = new mvDevicePic;
			else if(item.data.@nodeType == "NCM") 
				itemView.devPic = new ncmPic;
			else if(item.data.@nodeType == "Printer") 
				itemView.devPic = new printerPic;
			else
			{
				itemView.devPic = new firewallPic;
			}
			
			itemView.itemId = item.id;
			
			itemView.devPic.alpha = 1.0;
			itemView.devPic.x = 0;
			itemView.devPic.y = 0;
			itemView.addChild(itemView.devPic);
			
			if((item.data.@nodeType == "VLAN") || (item.data.@nodeType == "Group") || (txtInfo == "name"))
				itemView.txt.text = item.data.@name;
			else
				itemView.txt.text = item.data.@ip;
			
			
			itemView.txt.autoSize = TextFieldAutoSize.CENTER;
			itemView.txt.y = itemView.devPic.height;
			itemView.addChild(itemView.txt);
			
			itemView.height = itemView.devPic.height;
			itemView.width = itemView.devPic.width;
			
			/*
			var tf1:TextFormat = new TextFormat('',numNodeFontSize);
			tf1.color = String(numNodeFontColor);
			
			if(item.numChild != item.numShownChild)
				itemView.hiddenNodes.text = item.numShownChild + "/" + item.numChild;
			else
				itemView.hiddenNodes.text = "";
			itemView.hiddenNodes.setTextFormat(tf1);
			itemView.hiddenNodes.defaultTextFormat = tf1;
			itemView.hiddenNodes.selectable = false;
			itemView.hiddenNodes.y = 0 - 15;
			itemView.hiddenNodes.autoSize = TextFieldAutoSize.LEFT;
			itemView.hiddenNodes.backgroundColor = 0x0000ff;
			itemView.hiddenNodes.x = itemView.width - itemView.hiddenNodes.width + 15;
			
			if(item.data.@nodeType != "Cloud")
				itemView.addChild(itemView.hiddenNodes);*/
			
			var tf2:TextFormat = new TextFormat('',txtFontSize);
			tf2.color = String(txtFontColor);
			itemView.txt.setTextFormat(tf2);
			itemView.txt.selectable = false;
			
			itemView.devPic.x = (itemView.width - itemView.devPic.width)/2;
			itemView.txt.x = (itemView.width - itemView.txt.width)/2;
			
			itemView.scaleX = itemScale;
			itemView.scaleY = itemScale;
			
			itemView.data = item.data;
			
			setClickEvent(itemView, item);
		
			if(showAttack == true)
			{
				if(item.attackVictimID != 0)
				{
					itemView.atkPic = new attackVictimPic;
					itemView.atkPic.alpha = 0.7;
					itemView.atkPic.x = 20;
					itemView.addChild(itemView.atkPic);
					
					var myContextMenu : ContextMenu = new ContextMenu();
					myContextMenu.hideBuiltInItems();
					
										
					for each (var menuItemXML: XML in item.atkXML.descendants("RMenuItem"))
					{
						var GoUrlItem : ContextMenuItem = new ContextMenuItem(menuItemXML.@label);
						itemView.menuURL[menuItemXML.@label+"_"+item.id] = menuItemXML.@url;
						GoUrlItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, GoAtkUrl);
						if(menuItemXML.@enabled == "true")
							GoUrlItem.enabled = true;
						else
							GoUrlItem.enabled = false;
						myContextMenu.customItems.push(GoUrlItem);	
					
					}
					
					itemView.atkPic.contextMenu = myContextMenu;
					
				}
				
				if(item.attackSrcID != 0)
				{
					itemView.atkPic = new attackSrcPic;
					itemView.atkPic.alpha = 0.7;
					if(item.attackSrcID == -1)
					{
						itemView.atkPic.x = atkIsoX;
						itemView.atkPic.y = atkIsoY;
					}
					else
						itemView.atkPic.x = 20;
					itemView.addChild(itemView.atkPic);
					
					var myContextMenuSrc : ContextMenu = new ContextMenu();
					myContextMenuSrc.hideBuiltInItems();
					
					for each (var menuItemXMLSrc: XML in item.atkXML.descendants("RMenuItem"))
					{
						var GoUrlItemSrc : ContextMenuItem = new ContextMenuItem(menuItemXMLSrc.@label);
						itemView.menuURL[menuItemXMLSrc.@label+"_"+item.id] = menuItemXMLSrc.@url;
						GoUrlItemSrc.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, GoAtkUrl);
						if(menuItemXMLSrc.@enabled == "true")
							GoUrlItemSrc.enabled = true;
						else
							GoUrlItemSrc.enabled = false;
						myContextMenuSrc.customItems.push(GoUrlItemSrc);	
					}
					
					itemView.atkPic.contextMenu = myContextMenuSrc;
				}
			}
			
			if(showStatus == true)
			{
				if(null != itemView.statusCircle)
					itemView.removeChild(itemView.statusCircle);
				
				if(item.status != 0xff)
				{
					switch(item.status)
					{
						case 0:
						case 1:
							itemView.statusCircle = new status1Pic;
							break;
						case 2:
							itemView.statusCircle = new status2Pic;
							break;
						case 3:
							itemView.statusCircle = new status3Pic;
							break;
						case 4:
							itemView.statusCircle = new status4Pic;
							break;
						default:
							itemView.statusCircle = new status5Pic;
							break;
					}
					itemView.statusCircle.visible = true;
					itemView.statusCircle.alpha = 0.5;	
					itemView.addChild(itemView.statusCircle);
				}
			}
			
			itemView.alpha = viewAlpha;
			
			if(item.data.@nodeType == "MvDevice")
			{
				if(item.data.@name == "" || item.data.@ip == "")
					itemView.alpha = 0.13;
			}
			
			return itemView;
		}
		
		public var showAttack:Boolean = false;
		public var showStatus:Boolean = false;
		public var itemScale:Number = 0.5;
		public var txtInfo:String = "ip";
		public var viewAlpha:Number = 1.0;
		public var txtFontSize:int = 24;
		public var txtFontColor:int = 0x000000;
		public var numNodeFontSize:int = 30;
		public var numNodeFontColor:int = 0x0000ff;
		public var mrtgDirPath:String = "../mrtgdata/";
		public var clickEventXML:XML = null;
		public var sessionID:String = "";
		public var atkIsoX:int = 20;
		public var atkIsoY:int = 0;
	}
}

