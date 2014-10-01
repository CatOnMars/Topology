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
	import com.adobe.flex.extras.controls.springgraph.Graph;
	import com.adobe.flex.extras.controls.springgraph.IEdgeRenderer;
	import com.adobe.flex.extras.controls.springgraph.Item;
	
	import flash.display.Graphics;
	
	import mx.controls.Alert;
	import mx.core.IDataRenderer;
	import mx.core.UIComponent;

	
	public class myEdgeRenderer implements IEdgeRenderer
	{
		public var showRate:Boolean;
		public var showAttack:Boolean = false;
		public var rateThickness:int = 2;
		public var sepDepth:Number = 2;
		public var aBackDepth:Number = 9;
		public var aOpenWidth:Number = 4;
		
		/** SpringGraph will call this function each time it needs to draw
		 * a link connecting two itemRenderer.
		 * Note that fromView.data is the 'from' Item and toView.data is the 'to' Item.
		 * @param g a Flash graphics object, representing the entire screen area of the 
		 * SpringGraph component. You can use various Flash drawing commands to draw
		 * onto this drawing surface
		 * @param fromView the itemRenderer instance for the 'from' Item of this linik
		 * @param toView the itemRenderer instance for the 'to' Item of this link
		 * @param fromX the x-coordinate of fromView
		 * @param fromY the y-coordinate of fromView
		 * @param toX the x-coordinate of toView
		 * @param toY the y-coordinate of toView
		 * @param graph the Graph that we are drawing
		 * @return true if we successfully drew the edge, false if we want the SpringGraph
		 * to draw the edge. 
		 */
		public function draw(g: Graphics, fromView: UIComponent, toView: UIComponent,
					  fromX: int, fromY: int, toX: int, toY: int, graph: Graph): Boolean
		{
			var fromItem: Item = (fromView as IDataRenderer).data as Item;
			var toItem: Item = (toView as IDataRenderer).data as Item;
			var linkData: Object = graph.getLinkData(fromItem, toItem);
			var alpha: Number = 1.0;
			var thickness: int = 1;
			var color:int = 0;
			
			var len:Number, unitX:Number, unitY:Number;
			var realMidX:Number = (fromX + toX)/2, midX:Number;
			var realMidY:Number = (fromY + toY)/2, midY:Number;
			
			var arrowX:Number, arrowY:Number, pointX:Number, pointY:Number;
			
			
			//trace("(linkData!=null):"+(linkData!=null));
			//trace("(linkData.hasOwnProperty(settings)):"+(linkData.hasOwnProperty("settings")));
			
			//trace("fromItem.data.@id"+fromItem.data.@id);
			//trace("toItem.data.@id"+toItem.data.@id);
			
			if(showAttack == true)
			{
				var attackMskAndResult:int;
				attackMskAndResult = fromItem.attackPathMsk & toItem.attackPathMsk;
				if(attackMskAndResult != 0)
				{
					if(attackMskAndResult & (1 << 1))
						g.lineStyle(4,0x111111,0.9);
					else if(attackMskAndResult & (1 << 2))
						g.lineStyle(4,0x1111FF,0.9);
					else if(attackMskAndResult & (1 << 3))
						g.lineStyle(4,0x11FF11,0.9);
					else if(attackMskAndResult & (1 << 4))
						g.lineStyle(4,0xFF1111,0.9);
					
					g.beginFill(0);
					g.moveTo(fromX, fromY);
					g.lineTo(toX, toY);
					g.endFill();
					return true;
				}
			}
			
			if(showRate == false)
			{
				g.lineStyle(1,0x111111,0.9);
				g.beginFill(0);
				g.moveTo(fromX, fromY);
				g.lineTo(toX, toY);
				g.endFill();
			}
			else
			{
				if((linkData != null) && (linkData.hasOwnProperty("settings"))) {
					var settings: Object = linkData.settings;
					alpha = settings.alpha;
					thickness = rateThickness;
					color = settings.color;
					
					if(color == 0x123456)
					{
						g.lineStyle(1,0x111111,0.9);
						g.beginFill(0);
						g.moveTo(fromX, fromY);
						g.lineTo(toX, toY);
						g.endFill();
						return true;
					}
				}
				g.lineStyle(thickness,color,alpha);
				g.beginFill(0);
				g.moveTo(fromX, fromY);
				len = (realMidX - fromX) * (realMidX - fromX) + (realMidY - fromY)*(realMidY - fromY);
				len = Math.sqrt(len);
				unitX = (realMidX - fromX) * 1/len;
				unitY = (realMidY - fromY) * 1/len;
				midX = unitX * (-sepDepth) + realMidX;
				midY = unitY * (-sepDepth) + realMidY;
				g.lineTo(midX, midY);
								
				pointX = unitX*(-aBackDepth) + midX;
				pointY = unitY*(-aBackDepth) + midY;

				arrowX = pointX + unitY*(aOpenWidth);
				arrowY = pointY - unitX*(aOpenWidth);
				g.moveTo(midX, midY);
				g.lineTo(arrowX, arrowY);
				
				arrowX = pointX - unitY*aOpenWidth;
				arrowY = pointY + unitX*aOpenWidth;
				g.moveTo(midX, midY);
				g.lineTo(arrowX, arrowY);
							
				g.endFill();
				
				alpha = 1.0;
				thickness = 1;
				color = 0;
				
				linkData = graph.getLinkData(toItem, fromItem);
				
				if((linkData != null) && (linkData.hasOwnProperty("settings"))) {
					var settings: Object = linkData.settings;
					alpha = settings.alpha;
					thickness = rateThickness;
					color = settings.color;
				}
				
				g.lineStyle(thickness,color,alpha);
				g.beginFill(0);
				midX = unitX * sepDepth + realMidX;
				midY = unitY * sepDepth + realMidY;
				g.moveTo(midX, midY);
				g.lineTo(toX, toY);
				
				pointX = unitX*aBackDepth + midX;
				pointY = unitY*aBackDepth + midY;

				arrowX = pointX + unitY*aOpenWidth;
				arrowY = pointY - unitX*aOpenWidth;
				g.moveTo(midX, midY);
				g.lineTo(arrowX, arrowY);
				
				arrowX = pointX - unitY*aOpenWidth;
				arrowY = pointY + unitX*aOpenWidth;
				g.moveTo(midX, midY);
				g.lineTo(arrowX, arrowY);
				
				g.endFill();
			}
			return true;
		}
	}
	
	
}