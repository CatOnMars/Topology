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
	
	/** @private */
	public class HistorySeedView extends DefaultItemView
	{
		// We happen to know that the first x/y values we 
		// are given are the center x and center y of the springgraph.
		// We lock the Y value to this number, and never allow it to be 
		// chnaged again. We don't lock the X value, but we insist it is always
		// on the left side of the screen. These rules ensure that, when autoFit
		// and showHistory and tidyHistory are all enabled, the history 
		// forms a cluster on the middle left side of the screen.
		private var gotY: Boolean = false;
		private var gotX: Boolean = false;
		private var firstX: Number;

		// todo: only lock these x/y values if we are in autoFit mode
	    override public function set x(value:Number):void
	    {
	    	if(!gotX) {
	    		firstX = value / 3;
	    		gotX = true;
	    	}
	    	
    		if(value > firstX) {
    			value = firstX;
    		}

	    	super.x = value;
	    }

	    override public function set y(value:Number):void
	    {
	    	if(!gotY) {
	    		super.y = value;
	    		gotY = true;
	    	}
		}
	}
}