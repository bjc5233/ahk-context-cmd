class OrderedArray {
	__new(){		
		static base := Object("__Set", ObjBindMethod(OrderedArray,"oaSet"), "_NewEnum", ObjBindMethod(OrderedArray,"oaNewEnum"))
		return Object("_keys", Object(), "base", base)
	}
	oaSet(obj, k, v){
		obj._keys.Push(k)
	}
	oaNewEnum(obj){
		static base := Object("Next", ObjBindMethod(OrderedArray,"oaEnumNext"))
		return Object("obj", obj, "enum", obj._keys._NewEnum(), "base", base)
	}
	oaEnumNext(e, ByRef k, ByRef v=""){
		if r := e.enum.Next(i,k)
			v := e.obj[k]
		return r
	}
}