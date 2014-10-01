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

import com.adobe.flex.extras.controls.forcelayout.IDataProvider;
import com.adobe.flex.extras.controls.forcelayout.IEdge;
import com.adobe.flex.extras.controls.forcelayout.IForEachEdge;
import com.adobe.flex.extras.controls.forcelayout.IForEachNode;
import com.adobe.flex.extras.controls.forcelayout.IForEachNodePair;
import com.adobe.flex.extras.controls.forcelayout.Node;

import flash.geom.Rectangle;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import mx.core.UIComponent;

 /** Manages the graph data for a SpringGraph
  * 
  * @author   Mark Shepherd
  * @private
  */
public class GraphDataProvider implements IDataProvider {
	private var nodeStore: Object/*{id: GraphNode}*/ = new Object();
	private var nodes: Array; /*{id: GraphNode}*/
	private var edges: Array;
	private var host: Object;	
	private var _layoutChanged: Boolean = false;
	private var _distance: int;
	public var boundary: Rectangle;

	public function getAllNodes(): Array
	{
		return nodes;
	}
	
	private function makeGraphNode(item: Item): GraphNode {
		var result: GraphNode;
		if(nodeStore.hasOwnProperty(item.id)) {
			result = nodeStore[item.id];
			
			/*if(result.item.numChild != result.item.numShownChild)
				(myItemView)(result.view).hiddenNodes.text = result.item.numShownChild + "/" + result.item.numChild;
			else
				(myItemView)(result.view).hiddenNodes.text = "";*/
			
			if(result.view.parent == null)
				host.addComponent(result.view);	
		} else {
			if(initDone == false)
			{
				result = new GraphNode(host.newComponentXY(item, item.X, item.Y), this, item);
				trace("add item " + item.id + " X:" + item.X + " Y:" + item.Y);
			}
			else
			{
				result = new GraphNode(host.newComponent(item), this, item);
				trace("add item " + item.id);
			}
			nodeStore[item.id] = result;
		}
		return result;
	}

	public function clearAttackNodes():void
	{
		for each (var node: GraphNode in nodes) {
			if((node.item.attackSrcID != 0) || (node.item.attackVictimID != 0))
			{
				node.item.attackSrcID = 0;
				node.item.attackVictimID = 0;
				var nodeX:int = node.view.x;
				var nodeY:int = node.view.y;
				host.removeComponent(node.view);
				delete nodeStore[node.item.id];
				nodeStore[node.item.id] = new GraphNode(host.newComponentXY(node.item, nodeX, nodeY), this, node.item);
			}
			
			node.item.attackPathMsk = 0;
		}
	}
	
	public function reDrawAttackNodes():void
	{
		for each (var node: GraphNode in nodes) {
			if((node.item.attackSrcID != 0) || (node.item.attackVictimID != 0))
			{
				var nodeX:int = node.view.x;
				var nodeY:int = node.view.y;
				host.removeComponent(node.view);
				delete nodeStore[node.item.id];
				nodeStore[node.item.id] = new GraphNode(host.newComponentXY(node.item, nodeX, nodeY), this, node.item);
			}
		}
	}
	
	public function clearStatus():void
	{
		for each (var node: GraphNode in nodes) {
			if((myItemView)(node.view).statusCircle != null)
				(myItemView)(node.view).statusCircle.visible = false;
		}
	}
	
	public function reDrawStatus():void
	{
		for each (var node: GraphNode in nodes) {
			var nodeX:int = node.view.x;
			var nodeY:int = node.view.y;
			host.removeComponent(node.view);
			delete nodeStore[node.item.id];
			nodeStore[node.item.id] = new GraphNode(host.newComponentXY(node.item, nodeX, nodeY), this, node.item);
		}
	}
	
	public function GraphDataProvider(host: Object): void {
		this.host = host;
	}

	public function forAllNodes(fen: IForEachNode): void {
		for each (var node: Node in nodes) {
			fen.forEachNode(node);
		}
	}
	
	public function forAllEdges(fee: IForEachEdge): void {
		for each (var edge: IEdge in edges) {
			fee.forEachEdge(edge);
		}
	}
	
	public function forAllNodePairs(fenp: IForEachNodePair): void {
		for each (var nodeI: Node in nodes) {
			for each (var nodeJ: Node in nodes) {
				if(nodeI != nodeJ) {
					fenp.forEachNodePair(nodeI, nodeJ);
				}
			}
		}
	}
	
	public var initDone:Boolean = false;
	
	public function set graph(g: Graph): void {
		var newItems: Object = g.nodes;
		var newEdges: Object = g.edges;
		
		// re-create the list of nodes
		var oldNodes: Array = nodes;
		
		nodes = new Array();
		for each (var item: Item in newItems) {
			nodes.push(makeGraphNode(item));
		}
		if(oldNodes != null) {
			for each (var oldNode: GraphNode in oldNodes) {
				if(!g.hasNode(oldNode.item.id)) {
					// this node is not in the currently displayed set
					if(oldNode.view.parent != null)
						host.removeComponent(oldNode.view);
						delete nodeStore[oldNode.item.id];
						// !!@ how does it get re-added
				}
			}
		}

		// re-create the list of edges
		edges = new Array();
		for each (var edge: Array in newEdges) {
			edges.push(new GraphEdge(GraphNode(nodeStore[Item(edge[0]).id]), GraphNode(nodeStore[Item(edge[1]).id]), _distance));
		}
		
		trace("init Done");
		//initDone = true;
	}

	public function set distance(d: int): void {
		_distance = d;
	}
	
	public function get distance(): int {
		return _distance;
	}

	public function getEdges(): Array {
		return edges;
	}
	
	public function findNode(component: UIComponent): GraphNode {
		for (var i: int = 0; i < nodes.length; i++) {
			var node: GraphNode = GraphNode(nodes[i]);
			if(node.view == component)
				return node;
		}
		return null;
	}
	
	public function findNodeByID(id: String): GraphNode {
		if(nodes != null)
		{
			for (var i: int = 0; i < nodes.length; i++) {
				var node: GraphNode = GraphNode(nodes[i]);
				if(node != null)
					if(node.item.id == id)
						return node;
			}
			trace("node " + id + " not found");
			return null;
		}
		else
			return null;
	}

	public function get layoutChanged(): Boolean {
		return _layoutChanged;
	}
	
	public function set layoutChanged(b: Boolean): void{
		_layoutChanged = b;
	}
	
	public function get repulsionFactor(): Number {
		return SpringGraph(host)._repulsionFactor;
	}
	
	public function get defaultRepulsion(): Number {
		return SpringGraph(host).defaultRepulsion;
	}
	
	public function get hasNodes(): Boolean {
		return (nodes != null) && (nodes.length > 0);
	}
}
}
