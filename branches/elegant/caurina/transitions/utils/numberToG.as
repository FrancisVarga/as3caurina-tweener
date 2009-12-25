package caurina.transitions.utils {
	
	public function numberToG(p_num:Number): Number {
		return (p_num & 0xff00) >> 8;
	}
}
