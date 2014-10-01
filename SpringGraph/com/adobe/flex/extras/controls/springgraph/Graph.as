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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.HSlider;
	
	/**
	 *  Dispatched when there is any change to the nodes and/or links of this graph.
	 *
	 *  @eventType flash.events.Event
	 */
	[Event(name="changed", type="flash.events.Event")]
	
	/**
	 *  A Graph is a collection of items that can be linked to each other.
	 * 
	  * @author   Mark Shepherd
	 */
 	public class Graph extends EventDispatcher
	{
		public static const CHANGE:String = "change";

		public function Graph(): void {
		}
				
		private var _nodes: Object = new Object(); // map of id -> Item
		private var _edges: Object = new Object(); // map of id -> (map of id -> 0)
		public var baseNodeArray: Array/*of Item*/;
		private var nodeArray: Array/*of Item*/; 
		private var edgeArray: Array/*of [Item, Item]*/;
		private var _distinguishedItem: Item;
		public var vlanNodes: Object = new Object(); // map of id -> Item for VLAN nodes
		public var duplicateNodes: Object = new Object(); // map of id -> Item for Duplicated nodes
		public var fstLayerNodes: Object = new Object(); // map of id -> Item for first layer nodes
		private var maxGroupIdx: int = 0;
		
	    /**
	     *  Creates a graph from XML. The XML you provide should contain 2 kinds of elements<br>
	     *  &lt;Node id="xxx" anything-else..../&gt;<br>
	     *  and<br>
	     *  &lt;Edge fromID="xxx" toID="yyy"/&gt;<br><br>
	     * <p>You can have additional tags, and/or nest the tags any way you like; this will not
	     * have any effect. We create a graph where each Item corresponds to a single node. The item's
	     * id will come from the Node's id attribute (make sure this is unique). The item's data will
	     * be the Node, and will be of type XML. The &lt;Edge&gt; elements must come *after* the corresponding
	     * &lt;Node&gt; elements have appeared. Edges are not directional, you can interchange fromID and toID
	     * with no effect.
	     *
	     *  @param xml an XML document containing Node and Edge elements
	     *  @param strings the XML element and attribute names to use when parsing an XML dataProvider.
		   The array must have 4 elements:
		   <ul>
		   <li> the element name that defines nodes
		   <li> the element name that defines edges
		   <li> the edge attribute name that defines the 'from' node
		   <li> the edge attribute name that defines the 'to' node
		   </ul>
	     *  @return a graph that corresponds to the Node and Edge elements in the input
	     */
		public static function fromXML(xml: XML, strings: Array): Graph {
			var nodeName: String = "Node";
			var edgeName: String = "Edge";
			var fromIDName: String = "fromID";
			var toIDName: String = "toID";

			if(strings != null) {
				nodeName = strings[0];
				edgeName = strings[1];
				fromIDName = strings[2];
				toIDName = strings[3];
			}
			
			var graph: Graph = new Graph();
			for each (var node: XML in xml.descendants(nodeName)) {
				var item: Item = new Item(node.@id);
				item.data = node;
				graph.add(item);
			}
			
			for each (var edge: XML in xml.descendants(edgeName)) {
				var fromItem: Item = graph.find(edge.attribute(fromIDName));
				var toItem: Item = graph.find(edge.attribute(toIDName));
				if((fromItem != null) && (toItem != null))
					graph.link(fromItem, toItem);
			}
			
			return graph;
		}
		
		public var idx:int = 0;
		
		public function updateFromXML(xml: XML, lineXml: XML, strings: Array, isHideVlan: Boolean, isHideGroup: Boolean, centralItemID: String): void {
			
			var nodeName: String = "Node";
			var nodeTypeName: String = "nodeType";
			var ipName: String = "ip";
			var idxName: String = "idx";
			
			var edgeName: String = "Edge";
			var fromIDName: String = "fromID";
			var toIDName: String = "toID";
			var rxRateName: String = "rxRate";
			var txRateName: String = "txRate";
			var bwName: String = "bw";
			
			this.empty();
			maxGroupIdx = 0;
			idx+= 1;
			
			if(strings != null) {
				nodeName = strings[0];
				edgeName = strings[1];
				fromIDName = strings[2];
				toIDName = strings[3];
			}
			
			baseNodeArray = new Array();
						
			for each (var node: XML in xml.descendants(nodeName)) {
				var item: Item;
				var realItem: Item;
				item = new Item(node.@id);
				item.data = node;
				
				if(node.@nodeType == "ring")
				{
					realItem = this.findByIP(node.@ip);
					if(realItem != null)
					{
						realItem.nextLayerType = 1;
						this.addDuplicate(item);
					}
				}
				else if(node.@nodeType == "mesh")
				{
					realItem = this.findByIP(node.@ip);
					if(realItem != null)
					{
						realItem.nextLayerType = 2;
						this.addDuplicate(item);
					}
				}
				else
				{
					realItem = this.findByIP(node.@ip);
					if(realItem == null)
					{
						this.add(item);
						
						if(node.@nodeType == "Router" || node.@nodeType == "VLAN" || node.@nodeType == "Firewall" || node.@nodeType == "Group")
						{
							baseNodeArray.push(item);
							trace("baseNode added");
						}
						
						if(String(node.@id).length == 3)
						{
							this.addFirstLayer(item);
						}
					}
					else
					{
						this.addDuplicate(item);
					}
					
				}
				
			}
			
			for each (var edge: XML in xml.descendants(edgeName)) {
				var fromItem: Item = this.findDuplicate(edge.attribute(fromIDName));
				if(fromItem != null && fromItem.data.@ip != null)
				{
					fromItem = this.findByIP(fromItem.data.@ip);
				}
				if(fromItem == null)
					fromItem = this.find(edge.attribute(fromIDName));
				
				var toItem: Item = this.find(edge.attribute(toIDName));
				if(toItem == null)
					toItem = this.findByIP(edge.attribute("toIP"));
				
				if(fromItem == null || toItem == null || fromItem.nextLayerType != 0)
					continue;
				
				if(true == isHideVlan)
				{
					if(toItem.data.@nodeType == "VLAN") /*router --> vlan*/
					{
						if(toItem.id != centralItemID)
						{
							toItem.parentItem = fromItem;
							continue;
						}

					}
					if(fromItem.data.@nodeType == "VLAN") /*vlan --> host*/
					{
						if(fromItem.id != centralItemID)
						{
							fromItem = fromItem.parentItem;
						}

					}
				}
				if(true == isHideGroup)
				{
					if(toItem.data.@nodeType == "Group") /*router --> group*/
					{
						if(toItem.id != centralItemID)
						{
							toItem.parentItem = fromItem;
							continue;
						}
					}
					if(fromItem.data.@nodeType == "Group") /*group --> host*/
					{
						if(fromItem.id != centralItemID)
						{
							fromItem = fromItem.parentItem;
						}
					}
				}
				
				
				toItem.parentItem = fromItem;
				fromItem.numChild ++;
				if((fromItem != null) && (toItem != null))
				{
					var rxRate:Number;
					var txRate:Number;
					var bandwidth:Number;
					var rxPercent:Number = 0;
					var txPercent:Number = 0;
					
					rxRate = edge.attribute(rxRateName);
					txRate = edge.attribute(txRateName);
					toItem.rxRate = rxRate;
					toItem.txRate = txRate;
					
					bandwidth = edge.attribute(bwName);
					
					if(bandwidth!=0)
					{
						rxPercent = (rxRate/bandwidth) * 100;
						txPercent = (txRate/bandwidth) * 100;
					}
					
					var data1:Object = new Object();
					
					if(txRate == -1)
						data1 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(txPercent >=0 && txPercent <= 25)
							data1 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(txPercent >25 && txPercent <= 50)
							data1 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(txPercent >50 && txPercent <= 75)
							data1 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(txPercent >75 && txPercent <= 100)
							data1 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(txPercent >100)
							data1 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					var data2:Object = new Object();
					if(rxRate == -1)
						data2 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(rxPercent >=0 && rxPercent <= 25)
							data2 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(rxPercent >25 && rxPercent <= 50)
							data2 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(rxPercent >50 && rxPercent <= 75)
							data2 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(rxPercent >75 && rxPercent <= 100)
							data2 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(rxPercent >100)
							data2 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					this.linkDoubleColor(fromItem, toItem, data1, data2);	
				}
				
			}
			
			for each (var edge: XML in lineXml.descendants(edgeName)) 
			{
				var fromItem: Item = this.findByIP(edge.attribute("fromIP"));
				var toItem: Item = this.findByIP(edge.attribute("toIP"));
				
				data1 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
				
				if(fromItem != null && toItem != null)
				{
					var rxRate:Number;
					var txRate:Number;
					var bandwidth:Number;
					var rxPercent:Number = 0;
					var txPercent:Number = 0;
					
					this.firstLayerConnect(fromItem, toItem);
					
					rxRate = edge.attribute(rxRateName);
					txRate = edge.attribute(txRateName);
					toItem.rxRate = rxRate;
					toItem.txRate = txRate;
					
					bandwidth = edge.attribute(bwName);
					
					if(bandwidth!=0)
					{
						rxPercent = (rxRate/bandwidth) * 100;
						txPercent = (txRate/bandwidth) * 100;
					}
					
					var data1:Object = new Object();
					
					if(txRate == -1)
						data1 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(txPercent >=0 && txPercent <= 25)
							data1 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(txPercent >25 && txPercent <= 50)
							data1 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(txPercent >50 && txPercent <= 75)
							data1 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(txPercent >75 && txPercent <= 100)
							data1 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(txPercent >100)
							data1 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					var data2:Object = new Object();
					if(rxRate == -1)
						data2 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(rxPercent >=0 && rxPercent <= 25)
							data2 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(rxPercent >25 && rxPercent <= 50)
							data2 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(rxPercent >50 && rxPercent <= 75)
							data2 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(rxPercent >75 && rxPercent <= 100)
							data2 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(rxPercent >100)
							data2 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					this.linkDoubleColor(fromItem, toItem, data1, data2);
				}
			}
			
			this.firstLayerHiddenConnect();
			
		}
		
		public function updateFromXMLRmVlan(xml: XML, strings: Array): void {
			
			var nodeName: String = "Node";
			var nodeTypeName: String = "nodeType";
			var ipName: String = "ip";
			var idxName: String = "idx";
			
			var edgeName: String = "Edge";
			var fromIDName: String = "fromID";
			var toIDName: String = "toID";
			var rxRateName: String = "rxRate";
			var txRateName: String = "txRate";
			var bwName: String = "bw";
			
			this.empty();
			
			if(strings != null) {
				nodeName = strings[0];
				edgeName = strings[1];
				fromIDName = strings[2];
				toIDName = strings[3];
			}
			
			baseNodeArray = new Array();
			
			for each (var node: XML in xml.descendants(nodeName)) {
				var item: Item = new Item(node.@id);
				item.data = node;
				
				this.add(item);
				/*
				if(node.@nodeType == "VLAN")
					this.addVlan(item);
				if(node.@nodeType == "Router")
				{
					baseNodeArray.push(item);
					trace("baseNode added");
				}*/
			}
			
			for each (var edge: XML in xml.descendants(edgeName)) {
				var fromItem: Item = this.find(edge.attribute(fromIDName));
				var toItem: Item = this.find(edge.attribute(toIDName));
				if(toItem.data.@nodeType == "VLAN") /*router --> vlan*/
				{
					toItem.parentItem = fromItem;
					continue;
				}
				if(fromItem.data.@nodeType == "VLAN") /*vlan --> host*/
				{
					fromItem = fromItem.parentItem;
				}
				
				toItem.parentItem = fromItem;
				fromItem.numChild ++;
				if((fromItem != null) && (toItem != null))
				{
					var rxRate:Number;
					var txRate:Number;
					var bandwidth:Number;
					var rxPercent:Number = 0;
					var txPercent:Number = 0;
					
					rxRate = edge.attribute(rxRateName);
					txRate = edge.attribute(txRateName);
					toItem.rxRate = rxRate;
					toItem.txRate = txRate;
					
					bandwidth = edge.attribute(bwName);
					
					if(bandwidth!=0)
					{
						rxPercent = (rxRate/bandwidth) * 100;
						txPercent = (txRate/bandwidth) * 100;
					}
					
					var data1:Object = new Object();
					
					if(txRate == -1)
						data1 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(txPercent >=0 && txPercent <= 25)
							data1 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(txPercent >25 && txPercent <= 50)
							data1 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(txPercent >50 && txPercent <= 75)
							data1 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(txPercent >75 && txPercent <= 100)
							data1 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(txPercent >100)
							data1 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					var data2:Object = new Object();
					if(rxRate == -1)
						data2 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(rxPercent >=0 && rxPercent <= 25)
							data2 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(rxPercent >25 && rxPercent <= 50)
							data2 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(rxPercent >50 && rxPercent <= 75)
							data2 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(rxPercent >75 && rxPercent <= 100)
							data2 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(rxPercent >100)
							data2 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					this.linkDoubleColor(fromItem, toItem, data1, data2);	
				}
			}
			
		}

		public function updateRateXML(xml: XML, lineXml: XML, strings: Array, isHideVlan: Boolean, isHideGroup: Boolean): void {
						
			var nodeName: String = "Node";
			var nodeTypeName: String = "nodeType";
			var ipName: String = "ip";
			var idxName: String = "idx";
			
			var edgeName: String = "Edge";
			var fromIDName: String = "fromID";
			var toIDName: String = "toID";
			var rxRateName: String = "rxRate";
			var txRateName: String = "txRate";
			var bwName: String = "bw";
			
			if(strings != null) {
				nodeName = strings[0];
				edgeName = strings[1];
				fromIDName = strings[2];
				toIDName = strings[3];
			}
			
			for each (var node: XML in xml.descendants(nodeName)) {
				if(node.@nodeType == "MvDevice")
				{
					var devItem: Item = this.find(node.@id);
					devItem.data = node;
					if(devItem.data.@name == "" || devItem.data.@ip == "")
					{
						devItem.specialAlpha = 0.13;
					}
					else
						devItem.specialAlpha = 0;
				}
								
			}
			
			for each (var edge: XML in xml.descendants(edgeName)) {
								
				var fromItem: Item = this.findDuplicate(edge.attribute(fromIDName));
				if(fromItem != null && fromItem.data.@ip != null)
				{
					fromItem = this.findByIP(fromItem.data.@ip);
				}
				if(fromItem == null)
					fromItem = this.find(edge.attribute(fromIDName));
				
				
				var toItem: Item = this.find(edge.attribute(toIDName));
				if(toItem == null)
					toItem = this.findByIP(edge.attribute("toIP"));
				
				if(fromItem == null || toItem == null || fromItem.nextLayerType != 0)
					continue;
				
				if(true == isHideVlan)
				{
					if(toItem.data.@nodeType == "VLAN") /*router --> vlan*/
					{
						toItem.parentItem = fromItem;
						continue;
					}
					if(fromItem.data.@nodeType == "VLAN") /*vlan --> host*/
					{
						fromItem = fromItem.parentItem;
					}
				}
				if(true == isHideGroup)
				{
					if(toItem.data.@nodeType == "Group") /*router --> group*/
					{
						toItem.parentItem = fromItem;
						continue;
					}
					if(fromItem.data.@nodeType == "Group") /*group --> host*/
					{
						fromItem = fromItem.parentItem;
					}
				}
				
								
				if((fromItem != null) && (toItem != null))
				{
					var rxRate:Number;
					var txRate:Number;
					var bandwidth:Number;
					var rxPercent:Number = 0;
					var txPercent:Number = 0;
					
					rxRate = edge.attribute(rxRateName);
					txRate = edge.attribute(txRateName);
					toItem.rxRate = rxRate;
					toItem.txRate = txRate;
					
					bandwidth = edge.attribute(bwName);
					
					if(bandwidth!=0)
					{
						rxPercent = (rxRate/bandwidth) * 100;
						txPercent = (txRate/bandwidth) * 100;
					}
					
					var data1:Object = new Object();
					
					if(txRate == -1)
						data1 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(txPercent >=0 && txPercent <= 25)
							data1 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(txPercent >25 && txPercent <= 50)
							data1 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(txPercent >50 && txPercent <= 75)
							data1 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(txPercent >75 && txPercent <= 100)
							data1 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(txPercent >100)
							data1 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					var data2:Object = new Object();
					if(rxRate == -1)
						data2 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(rxPercent >=0 && rxPercent <= 25)
							data2 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(rxPercent >25 && rxPercent <= 50)
							data2 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(rxPercent >50 && rxPercent <= 75)
							data2 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(rxPercent >75 && rxPercent <= 100)
							data2 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(rxPercent >100)
							data2 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					this.linkDoubleColor(fromItem, toItem, data1, data2);	
				}
				
			}
			
			for each (var edge: XML in lineXml.descendants(edgeName)) 
			{
				var fromItem: Item = this.findByIP(edge.attribute("fromIP"));
				var toItem: Item = this.findByIP(edge.attribute("toIP"));
				
				data1 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
				
				if(fromItem != null && toItem != null)
				{
					var rxRate:Number;
					var txRate:Number;
					var bandwidth:Number;
					var rxPercent:Number = 0;
					var txPercent:Number = 0;
					
					rxRate = edge.attribute(rxRateName);
					txRate = edge.attribute(txRateName);
					toItem.rxRate = rxRate;
					toItem.txRate = txRate;
					
					bandwidth = edge.attribute(bwName);
					
					if(bandwidth!=0)
					{
						rxPercent = (rxRate/bandwidth) * 100;
						txPercent = (txRate/bandwidth) * 100;
					}
					
					var data1:Object = new Object();
					
					if(txRate == -1)
						data1 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(txPercent >=0 && txPercent <= 25)
							data1 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(txPercent >25 && txPercent <= 50)
							data1 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(txPercent >50 && txPercent <= 75)
							data1 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(txPercent >75 && txPercent <= 100)
							data1 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(txPercent >100)
							data1 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					var data2:Object = new Object();
					if(rxRate == -1)
						data2 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(rxPercent >=0 && rxPercent <= 25)
							data2 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(rxPercent >25 && rxPercent <= 50)
							data2 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(rxPercent >50 && rxPercent <= 75)
							data2 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(rxPercent >75 && rxPercent <= 100)
							data2 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(rxPercent >100)
							data2 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					this.linkDoubleColor(fromItem, toItem, data1, data2);
				}
			}
			
			
			
		}
		
		public function updateRateXMLRmVlan(xml: XML, strings: Array = null): void {
			
			var nodeName: String = "Node";
			var nodeTypeName: String = "nodeType";
			var ipName: String = "ip";
			var idxName: String = "idx";
			
			var edgeName: String = "Edge";
			var fromIDName: String = "fromID";
			var toIDName: String = "toID";
			var rxRateName: String = "rxRate";
			var txRateName: String = "txRate";
			var bwName: String = "bw";
			
			if(strings != null) {
				nodeName = strings[0];
				edgeName = strings[1];
				fromIDName = strings[2];
				toIDName = strings[3];
			}
			
			for each (var edge: XML in xml.descendants(edgeName)) {
				var fromItem: Item = this.find(edge.attribute(fromIDName));
				var toItem: Item = this.find(edge.attribute(toIDName));
				if(toItem.data.@nodeType == "VLAN") /*router --> vlan*/
				{
					continue;
				}
				if(fromItem.data.@nodeType == "VLAN") /*vlan --> host*/
				{
					fromItem = fromItem.parentItem;
				}
				
				if((fromItem != null) && (toItem != null))
				{
					var rxRate:Number;
					var txRate:Number;
					var bandwidth:Number;
					var rxPercent:Number = 0;
					var txPercent:Number = 0;
					
					rxRate = edge.attribute(rxRateName);
					txRate = edge.attribute(txRateName);
					toItem.rxRate = rxRate;
					toItem.txRate = txRate;
					
					bandwidth = edge.attribute(bwName);
					
					if(bandwidth!=0)
					{
						rxPercent = (rxRate/bandwidth) * 100;
						txPercent = (txRate/bandwidth) * 100;
					}

					var data1:Object = new Object();
					if(txRate == -1)
						data1 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(txPercent >=0 && txPercent <= 25)
							data1 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(txPercent >25 && txPercent <= 50)
							data1 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(txPercent >50 && txPercent <= 75)
							data1 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(txPercent >75 && txPercent <= 100)
							data1 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(txPercent >100)
							data1 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					var data2:Object = new Object();
					if(rxRate == -1)
						data2 = {settings: {alpha: 0.9, color: /*specialCode*/0x123456, thickness: 4}};
					else
					{
						if(rxPercent >=0 && rxPercent <= 25)
							data2 = {settings: {alpha: 0.9, color: /*blue*/0x0030ff, thickness: 4}};
						else if(rxPercent >25 && rxPercent <= 50)
							data2 = {settings: {alpha: 0.9, color: /*green*/0x33d900, thickness: 4}};
						else if(rxPercent >50 && rxPercent <= 75)
							data2 = {settings: {alpha: 0.9, color: /*yellow*/0xffff00, thickness: 4}};
						else if(rxPercent >75 && rxPercent <= 100)
							data2 = {settings: {alpha: 0.9, color: /*orange*/0xff9c00, thickness: 4}};
						else if(rxPercent >100)
							data2 = {settings: {alpha: 0.9, color: /*red*/0xff0000, thickness: 4}};
					}
					
					this.linkDoubleColor(fromItem, toItem, data1, data2);	
				}
			}
			
		}
		
		public function setAttackPath(srcItem:Item, victimItem:Item, id:int, isHideVlan:Boolean, isHideGroup:Boolean):void
		{
			var srcIdLen:int = srcItem.id.length;
			var victimIdLen:int = victimItem.id.length;
			var parentId:String = null;
			var pathItem:Item = null;
			
			for(var len=3;len <= srcIdLen && len <= victimIdLen;len+=3)
			{
				if(srcItem.id.slice(0, len) == victimItem.id.slice(0, len))
				{
					pathItem = this.find(srcItem.id.slice(0, len));
					if(pathItem != null)
					{
						if(isHideVlan == true && pathItem.data.@nodeType == "VLAN")
							continue;
						if(isHideGroup == true && pathItem.data.@nodeType == "Group")
							continue;
						parentId = srcItem.id.slice(0, len);
					}
				}
			}
			
			if(parentId!= null)
			{
				for(var len=parentId.length; len<=srcIdLen; len+=3)
				{
					pathItem = this.find(srcItem.id.slice(0, len));
					if(pathItem != null)
						pathItem.attackPathMsk |= 1 << id;
				}
				
				for(var len=parentId.length; len<=victimIdLen; len+=3)
				{
					pathItem = this.find(victimItem.id.slice(0, len));
					if(pathItem != null)
						pathItem.attackPathMsk |= 1 << id;
				}
			}
		}
		
		public function setAttackPathRmVlan(srcItem:Item, victimItem:Item, id:int):void
		{
			var srcIdLen:int = srcItem.id.length;
			var victimIdLen:int = victimItem.id.length;
			var parentId:String = null;
			var pathItem:Item = null;
			
			for(var len=3;len <= srcIdLen && len <= victimIdLen;len+=3)
			{
				if(srcItem.id.slice(0, len) == victimItem.id.slice(0, len))
				{
					pathItem = this.find(srcItem.id.slice(0, len));
					if(pathItem != null)
						if(pathItem.data.@nodeType != "VLAN")
							parentId = srcItem.id.slice(0, len);
				}
			}
			
			if(parentId!= null)
			{
				for(var len=parentId.length; len<=srcIdLen; len+=3)
				{
					pathItem = this.find(srcItem.id.slice(0, len));
					if(pathItem != null)
						pathItem.attackPathMsk |= 1 << id;
				}
				
				for(var len=parentId.length; len<=victimIdLen; len+=3)
				{
					pathItem = this.find(victimItem.id.slice(0, len));
					if(pathItem != null)
						pathItem.attackPathMsk |= 1 << id;
				}
			}
		}
		
	    /**
	     *  Removes an item from the graph.
	     *
	     *  @param item The item that you want to remove from the graph.
	     */
		public function remove(item:Item):void
		{
			delete _nodes[item.id];
			delete _edges[item.id];
			
			for (var id: String in _edges) {
				var friends: Object = _edges[id];
				delete friends[item.id];
			}
			
			baseNodeArray = null;
			nodeArray = null;
			edgeArray = null;
			changed();
		}
		
	    /**
	     *  Remove the link between 2 items.
	     *
	     *  @param item1 an item in the graph that is linked to item2
	     *  @param item2 an item in the graph that is linked to item1
	     */
		public function unlink(item1:Item, item2:Item):void
		{
			var friends: Object = _edges[item1.id];
			delete friends[item2.id];
			
			friends = _edges[item2.id];
			delete friends[item1.id];
			
			edgeArray = null;
			changed();
		}
		
	    /**
	     *  An array of all the links in the graph.
	     *  Each array element is an array of 2 strings, 
	     *  which are the ids of two items that are linked.
	     */
		public function get edges():Array
		{
			if(edgeArray == null) {
				edgeArray = new Array();
				var done: Object = new Object();
				for (var id: String in _edges) {
					done[id] = true;
					var friends: Object = _edges[id];
					for (var friendID: String in friends) {
						if(!done.hasOwnProperty(friendID))
							edgeArray.push([_nodes[id], nodes[friendID]]);
					}
				}
			}
			return edgeArray;
		}
		
	    /**
	     *  An associative array of all the items in the graph.
	     *  The key is the id, the value is the Item.
	     */
		public function get nodes():Object
		{
			return _nodes;
		}
		
	    /**
	     *  True if this graph has any nodes at all.
	     */
		public function get hasNodes(): Boolean
		{
			for each (var item: Item in _nodes) {
				return true;
			}
			return false;
		}
		
	    /**
	     *  How many items are in this graph.
	     */
		public function get nodeCount(): int
		{
			var result:  int = 0;
			for each (var item: Item in _nodes) {
				result++;
			}
			return result;
		}
		
	    /**
	     *  Link 2 items. This has no effect if the 2 items are already
	     *  linked. Links are not directional: link(a,b) is equivalent to
	     *  link(b,a).
	     *
	     *  @param item1 an item in the graph
	     *  @param item2 an item in the graph
	     *  @param data any data you like, or null. The Graph doesn't ever look at this, 
	     * but you may find it convenient to store here. 
	     *  You can use getLinkData to retrieve this data later.
	     */
		public function link(item1:Item, item2:Item, data: Object = null):void
		{
			if(data == null) data = 0;
			
			var friends: Object = _edges[item1.id];
			friends[item2.id] = data;
			
			friends = _edges[item2.id];
			friends[item1.id] = data;
			
			edgeArray = null;
			changed();
		}
		
		public function linkDoubleColor(item1:Item, item2:Item, data1: Object = null, data2: Object = null):void
		{
			if(data1 == null) data1 = 0;
			if(data2 == null) data2 = 0;
			
			var friends: Object = _edges[item1.id];
			friends[item2.id] = data1;
			
			friends = _edges[item2.id];
			friends[item1.id] = data2;
			
			edgeArray = null;
			changed();
		}
	
	    /**
	     *  Add an item to the graph.
	     *
	     *  @param item an item to add to the graph
	     */
		public function add(item:Item):void
		{
			if(_distinguishedItem == null)
				_distinguishedItem = item;
				
			if(_nodes.hasOwnProperty(item.id)) {
				return;
			}
			
			_nodes[item.id] = item;
			_edges[item.id] = new Object();
			changed();
		}
		
		public function addVlan(item:Item):void
		{	
			if(vlanNodes.hasOwnProperty(item.id)) {
				return;
			}
			
			vlanNodes[item.id] = item;
		}
		
		public function addDuplicate(item:Item):void
		{
			if(duplicateNodes.hasOwnProperty(item.id)) {
				return;
			}
			
			duplicateNodes[item.id] = item;
		}
		
		public function addFirstLayer(item:Item):void
		{
			if(fstLayerNodes.hasOwnProperty(item.id)) {
				return;
			}
			
			fstLayerNodes[item.id] = item;
		}
		
	    /**
	     *  Find out if two items are linked.
	     *
	     *  @param item1 an item in the graph
	     *  @param item2 an item in the graph
	     *
	     *  @return true if the two items are linked to each other.
	     */
		public function linked(item1:Item, item2:Item):Boolean
		{
			var friends: Object = _edges[item1.id];
			return (friends != null) && friends.hasOwnProperty(item2.id);
		}
		
	    /**
	     *  retrieve the data that is associated with a link.
	     *
	     *  @param item1 an item in the graph
	     *  @param item2 an item in the graph
	     *
	     *  @return Object the data that was associated with the link between the two items.
	     *  If no data, or null, was associated with the link, we return 0. If there is no link
	     *  between the items, we return null.
	     */
		public function getLinkData(item1:Item, item2:Item):Object
		{
			var friends: Object = _edges[item1.id];
			
			if ((friends != null) && friends.hasOwnProperty(item2.id))
				return friends[item2.id];
			else
				return null;
		}
		
	    /**
	     *  Find out how many items are linked to a given item.
	     *
	     *  @param item an item in the graph
	     *
	     *  @return thes number of items to which this item is linked.
	     */
		public function numLinks(item: Item): int {
			var friends: Object = _edges[item.id];
			var result: int = 0;
			for (var i: String in friends) { 
				result++; 
			}
			return result;
		}
		
	    /**
	     *  Find out if an item with a given id exists in the graph.
	     *
	     *  @param id any String
	     *
	     *  @return true if there is an item in the graph with the given id,
	     *  false otherwise.
	     */
		public function hasNode(id: String): Boolean {
			return _nodes.hasOwnProperty(id);
		}
		
	    /**
	     *  Find an item in the graph by id.
	     *
	     *  @param id any String
	     *
	     *  @return the item in the graph that has the given id,
	     *  or null if there is no such item.
	     */
		public function find(id: String): Item {
			if(_nodes.hasOwnProperty(id))
				return _nodes[id];
			else
				return null;
		}
		
		public function findDuplicate(id: String): Item {
			if(duplicateNodes.hasOwnProperty(id))
				return duplicateNodes[id];
			else
				return null;
		}
		
		public function findByIP(ip: String): Item {
			for each (var item: Item in _nodes) {
				if((item.data.@ip == ip) && (item.data.@nodeType != "VLAN"))
				{
					return item;
				}
			}
			return null;
		}
		
		public function findItemArrayByIP(ip: String): Array {
			var itemArray:Array = new Array();
			for each (var item: Item in _nodes) {
				if((item.data.@ip == ip) && (item.data.@nodeType != "VLAN"))
				{
					itemArray.push(item);
				}
			}
			return itemArray;
		}
		
		public function findByIdx(idx: String): Item {
			for each (var item: Item in _nodes) {
				if(item.data.@idx == idx)
				{
					return item;
				}
			}
			return null;
		}
		
		public function findItemArrayByIdx(idx: String): Array {
			var itemArray:Array = new Array();
			for each (var item: Item in _nodes) {
				if(item.data.@idx == idx)
				{
					itemArray.push(item);
				}
			}
			return itemArray;
		}
		
		public function findByName(name: String): Item {
			for each (var item: Item in _nodes) {
				if(item.data.@name == name)
				{
					return item;
				}
			}
			return null;
		}
		
		public function findItemArrayByName(name: String): Array {
			var itemArray:Array = new Array();
			for each (var item: Item in _nodes) {
				if(item.data.@name == name)
				{
					itemArray.push(item);
				}
			}
			return itemArray;
		}
		
		public function clearNumShowChild(): void {
			for each (var item: Item in _nodes) {
				item.numShownChild = 0;
			}
		}
		
		public function firstLayerConnect(fromItem: Item, toItem: Item): void {
			if(fstLayerNodes.hasOwnProperty(fromItem.id) && fstLayerNodes.hasOwnProperty(toItem.id))
			{
				if(fromItem.fstLayerGroupIdx == 0 && toItem.fstLayerGroupIdx == 0)
				{
					maxGroupIdx = maxGroupIdx + 1;
					fromItem.fstLayerGroupIdx = maxGroupIdx;
					toItem.fstLayerGroupIdx = maxGroupIdx;
					//Alert.show(idx + " " +"1("+fromItem.data.@ip+","+fromItem.fstLayerGroupIdx+"),("+toItem.data.@ip+","+toItem.fstLayerGroupIdx+")");
				}
				else if(fromItem.fstLayerGroupIdx > toItem.fstLayerGroupIdx) 
				{
					if(toItem.fstLayerGroupIdx == 0)
					{
						toItem.fstLayerGroupIdx = fromItem.fstLayerGroupIdx;
						//Alert.show(idx + " " +"2("+fromItem.data.@ip+","+fromItem.fstLayerGroupIdx+"),("+toItem.data.@ip+","+toItem.fstLayerGroupIdx+")");
					}
					else
					{
						var targetIdx:int = toItem.fstLayerGroupIdx;
						for each (var item: Item in fstLayerNodes) {
							if(item.fstLayerGroupIdx == targetIdx)
							{
								item.fstLayerGroupIdx = fromItem.fstLayerGroupIdx;
								//Alert.show(idx + " " +"3("+fromItem.data.@ip+","+fromItem.fstLayerGroupIdx+"),("+toItem.data.@ip+","+toItem.fstLayerGroupIdx+")");
							}
						}
					}
				}
				else if(fromItem.fstLayerGroupIdx < toItem.fstLayerGroupIdx)
				{
					if(fromItem.fstLayerGroupIdx == 0)
					{
						fromItem.fstLayerGroupIdx = toItem.fstLayerGroupIdx;
						//Alert.show(idx + " " +"4("+fromItem.data.@ip+","+fromItem.fstLayerGroupIdx+"),("+toItem.data.@ip+","+toItem.fstLayerGroupIdx+")");
					}
					else
					{
						var targetIdx:int = fromItem.fstLayerGroupIdx;
						for each (var item: Item in fstLayerNodes) {
							if(item.fstLayerGroupIdx == targetIdx)
							{
								item.fstLayerGroupIdx = toItem.fstLayerGroupIdx;
								//Alert.show(idx + " " +"5("+fromItem.data.@ip+","+fromItem.fstLayerGroupIdx+"),("+toItem.data.@ip+","+toItem.fstLayerGroupIdx+")");
							}
						}
					}
				}
			}
			
		}
		
		public function firstLayerHiddenConnect(): void {
			
			var targetIdx:int = -1, rmvIdx;
			var centerItem: Item;
			var data1:Object = new Object();
			var data2:Object = new Object();
			var log:String = "";
			
			data1 = {settings: {alpha: 0, color: /*red*/0xff0000, thickness: 4}};
			data2 = {settings: {alpha: 0, color: /*red*/0xff0000, thickness: 4}};
			
			for each (var item: Item in fstLayerNodes) {
				log += "(" +item.data.@ip + "," + item.fstLayerGroupIdx + ")";
				
			}
			
			//Alert.show(log);
			
			for each (var item: Item in fstLayerNodes) {
				if(targetIdx == -1)
				{
					targetIdx = item.fstLayerGroupIdx;
					centerItem = item;
				}
				
				//Alert.show(centerItem.fstLayerGroupIdx+","+centerItem.data.@ip + "to" + item.fstLayerGroupIdx +","+item.data.@ip);
				
				if((item.fstLayerGroupIdx != targetIdx && item.fstLayerGroupIdx != -1) || item.fstLayerGroupIdx == 0)
				{
					this.linkDoubleColor(centerItem, item, data1, data2);
					//Alert.show(idx + " " +centerItem.id+","+centerItem.data.@ip + "to" + item.id +","+item.data.@ip);
					
					rmvIdx = item.fstLayerGroupIdx; 
					
					if(rmvIdx != 0)
					{
						for each (var itemTmp: Item in fstLayerNodes) 
						{
							if(rmvIdx == itemTmp.fstLayerGroupIdx)
							{
								itemTmp.fstLayerGroupIdx = -1; 
							}
						}
					}
					else
					{
						item.fstLayerGroupIdx  = -1;
					}
				}
			}
			
		}
		
		
	    /**
	     *  Get an array of all the items that a given item is linked to.
	     *
	     *  @param id any String
	     *
	     *  @return an array of Items
	     */
		public function neighbors(id: String): Object {
			return _edges[id];
		}
		
	    /** Sometimes it's handy for the graph to remember one particular item.
	     * You can use this for any purpose you like, it's not used internally by the Graph.
	     * By default, the distinguished item is the first item that was added to this graph.
	     */
		public function get distinguishedItem(): Item {
			return _distinguishedItem;
		}
		
		public function set distinguishedItem(item: Item): void {
			_distinguishedItem = item;
		}
		
		/** Remove all items from the graph. */
		public function empty(): void {
			_nodes = new Object();
			_edges = new Object();
			baseNodeArray = null;
			nodeArray = null;
			edgeArray = null;
			_distinguishedItem = null;
			fstLayerNodes = new Object();
			vlanNodes = new Object();
			changed();	
		}
		
		private function changed(): void {
			dispatchEvent(new Event(CHANGE));
		}
	}
}