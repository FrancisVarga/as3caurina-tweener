package caurina.transitions.utils {
	
	/**
	 * Returns the number of properties an object has
	 *
	 * @param		p_object			Object		Target object with a number of properties
	 * @return							Number		Number of total properties the object has
	 */
	public function getObjectLength(p_object:Object):uint {
		var totalProperties:uint = 0;
		for (var pName:String in p_object) totalProperties ++;
		return totalProperties;
	}
}
