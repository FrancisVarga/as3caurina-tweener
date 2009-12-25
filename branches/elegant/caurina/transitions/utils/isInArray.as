package caurina.transitions.utils {
	
	/**
	 * Checks whether a string is on an array
	 *
	 * @param		p_string			String		String to search for
	 * @param		p_array				Array		Array to be searched
	 * @return							Boolean		Whether the array contains the string or not
	 */
	public isInArray(p_string:String, p_array:Array):Boolean {
		var l:uint = p_array.length;
		for (var i:uint = 0; i < l; i++) {
			if (p_array[i] == p_string) return true;
		}
		return false;
	}
}
