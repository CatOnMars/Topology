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
	import mx.core.UIComponent;
	import mx.core.IDataRenderer;
	import flash.events.Event;
	
	/** @private */
	public class DefaultItemView extends UIComponent implements IDataRenderer
	{
		[Bindable("dataChange")]
		public function get data(): Object {
			return _data;
		}
		
		public function set data(d: Object): void {
			_data = d;
			dispatchEvent(new Event("dataChange"));
		}
		
		private var _data: Object = null; 
	}
}