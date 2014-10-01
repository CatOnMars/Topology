
package
{
	import flash.display.Graphics;
	import com.adobe.flex.extras.controls.springgraph.Item;
	import com.adobe.flex.extras.controls.springgraph.IMenuBarHandler;
	import mx.core.UIComponent;
	import mx.core.Application;
	import NetworkTopologyDemo;
	
	/** Defines an object that knows how to handle menubar in 
	 * a SpringGraph. */
	public class myMenuBarHandler implements IMenuBarHandler
	{
		/** SpringGraph will call this function to handle show rate 
		 */
		public function showRate(isShowRate:int): void
		{
			//app().displayRate(isShowRate);
		}
		
		/** SpringGraph will call this function to handle show attack 
		 */
		public function showAttack(isShowAttack:Boolean): void
		{
			//app().displayAttack(isShowAttack);
		}
		
		/** SpringGraph will call this function to handle set refresh interval 
		 */
		public function setRefreshInterval(refreshInterval:int): void
		{
			//app().displayAttack(isShowAttack);
		}
		
		private function app(): NetworkTopologyDemo {
			return Application.application as NetworkTopologyDemo;
		}
	}
}