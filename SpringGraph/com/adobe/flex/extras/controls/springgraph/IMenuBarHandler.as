
package com.adobe.flex.extras.controls.springgraph
{
	import flash.display.Graphics;
	import com.adobe.flex.extras.controls.springgraph.Item;
	import mx.core.UIComponent;
	
	/** Defines an object that knows how to handle menubar in 
	 * a SpringGraph. */
	public interface IMenuBarHandler
	{
		/** SpringGraph will call this function to handle show rate 
		 */
		function showRate(isShowRate:int): void;
		
		/** SpringGraph will call this function to handle show attack 
		 */
		function showAttack(isShowAttack:Boolean): void;
		
		/** SpringGraph will call this function to handle set refresh interval 
		 */
		function setRefreshInterval(refreshInterval:int): void;
	}
}