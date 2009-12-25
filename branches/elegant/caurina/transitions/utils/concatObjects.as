package caurina.transitions.utils {
	
	/* Takes a variable number of objects as parameters and "adds" their properties, from left to right. If a latter object defines a property as null, it will be removed from the final object
	* @param		args				Object(s)	A variable number of objects
	* @return							Object		An object with the sum of all paremeters added as properties.
	*/
	public function concatObjects(...args) : Object{
		var finalObject : Object = {};
		var currentObject : Object;
		for (var i : int = 0; i < args.length; i++){
			currentObject = args[i];
			for (var prop : String in currentObject){
				if (currentObject[prop] == null){
					// delete in case is null
					delete finalObject[prop];
				}else{
					finalObject[prop] = currentObject[prop]
				}
			}
		}
		return finalObject;
	}
}
