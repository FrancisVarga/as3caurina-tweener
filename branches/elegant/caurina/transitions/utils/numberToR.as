package caurina.transitions.utils {
	
	public function numberToR(p_num:Number): Number {
		return (p_num & 0xff0000) >> 16;
	}
}
