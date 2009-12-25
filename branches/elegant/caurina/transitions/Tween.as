package caurina.transitions {

	import caurina.transitions.utils.*;
	import caurina.transitions.Equations;
	import caurina.transitions.modifiers.roundValue;

	/**
	 * The tween list object. Stores all of the properties and information that pertain to individual tweens.
	 *
	 * @author		Nate Chatellier, Zeh Fernando, Arthur Debert
	 * @version		1.1.0
	 * @private
	 */

	public class Tween {

		// Instance properties
		internal var scope					:Object;	// Object affected by this tweening
		internal var properties				:Object;	// List of properties that are tweened
			// @ see TweenProperty
		internal var timeCreated			:Number;	// Time when this tweening was created
		internal var timeStart				:Number;	// Time when this tweening should start
		internal var timeComplete			:Number;	// Time when this tweening should end
		internal var timeDuration			:Number;	// Time this tween takes (cache)
		internal var transition				:Function;	// Equation to control the transition animation
		internal var transitionParams		:Object;	// Additional parameters for the transition
		internal var onStart				:Function;	// Function to be executed on the object when the tween starts (once)
		internal var onUpdate				:Function;	// Function to be executed on the object when the tween updates (several times)
		internal var onComplete				:Function;	// Function to be executed on the object when the tween completes (once)
		internal var onOverwrite			:Function;	// Function to be executed on the object when the tween is overwritten
		internal var onError				:Function;	// Function to be executed if an error is thrown when tweener exectues a callback (onComplete, onUpdate etc)
		internal var onStartParams			:Array;		// Array of parameters to be passed for the event
		internal var onUpdateParams			:Array;		// Array of parameters to be passed for the event
		internal var onCompleteParams		:Array;		// Array of parameters to be passed for the event
		internal var onOverwriteParams		:Array;		// Array of parameters to be passed for the event
		internal var onStartScope			:Object;	// Scope in which the event function is ran
		internal var onUpdateScope			:Object;	// Scope in which the event function is ran
		internal var onCompleteScope		:Object;	// Scope in which the event function is ran
		internal var onOverwriteScope		:Object;	// Scope in which the event function is ran
		internal var onErrorScope			:Object;	// Scope in which the event function is ran
		//internal var rounded				:Boolean;	// Use rounded values when updating
		internal var timePaused				:Number;	// Time when this tween was paused
		internal var skipUpdates			:uint;		// How many updates should be skipped (default = 0; 1 = update-skip-update-skip...)
		internal var updatesSkipped			:uint;		// How many updates have already been skipped
		internal var started				:Boolean;	// Whether or not this tween has already started

		protected var _useFrames			:Boolean;	// Whether or not to use frames instead of seconds
		protected var _paused				:Boolean;	// Whether or not this tween is currently paused
		
		// Public acessors
		// .time
		// .delay
		// .useFrames
		// .paused

		// ==================================================================================================================================
		// CONSTRUCTOR function -------------------------------------------------------------------------------------------------------------

		/**
		 * Creates a new Tween.
		 *
		 * @param	p_scope				Object		Object that this tweening refers to.
		 */
		public function Tween(p_scope:Object) {
			scope				=	p_scope;

			properties			=	new Object();

			timeCreated			=	getCurrentTime();
			timeStart			=	timeCreated;
			timeComplete		=	timeCreated;
			_useFrames			=	false;
			transition			=	Tweener.getTransition("easeoutexpo");
			transitionParams	=	new Array();

			onStartScope		=	p_scope;
			onUpdateScope		=	p_scope;
			onCompleteScope		=	p_scope;
			onErrorScope		=	p_scope;

			_paused				=	false;
			skipUpdates			=	0;
			updatesSkipped		=	0;
			started				=	false;
			
			updateCache();

		}

		// ==================================================================================================================================
		// MAIN functions -------------------------------------------------------------------------------------------------------------------

		public function parseParameters(p_parameters:Object): void {

    		var p_obj:Object = Tween.makePropertiesChain(p_parameters);

			// Parse hardcoded keywords
			if (!isNaN(p_obj.time))		time = p_obj.time;
			if (!isNaN(p_obj.delay))	delay = p_obj.delay;

			var newTransition:Object = p_obj.transition;
			if (Boolean(newTransition)) {
				if (typeof newTransition == "string") {
					// String parameter, transition names
					transition = Tweener.getTransition(newTransition.toLowerCase());
				} else {
					// Proper transition function
					transition = Function(newTransition);
				}
			}
			
			if (Boolean(p_obj.transitionParams)) transitionParams = p_obj.transitionParams;
			if (Boolean(p_obj.useFrames)) useFrames = true;

			// Parse actual properties
			var keywords:Object = {time:true, delay:true, useFrames:true, skipUpdates:true, transition:true, transitionParams:true, onStart:true, onUpdate:true, onComplete:true, onOverwrite:true, rounded:true, onStartParams:true, onUpdateParams:true, onCompleteParams:true, onOverwriteParams:true, onStartScope:true, onUpdateScope:true, onCompleteScope:true, onOverwriteScope:true, onErrorScope:true};
			for (var istr:String in p_obj) {
				if (!keywords[istr]) {
					// It's an additional pair, so adds
					properties[istr] = new TweenProperty(p_obj[istr]);
					
					// Applies value modifiers
					if (p_parameters.round) properties[istr].valueModifiers.push(roundValue);
				}
			}

			// TODO: verificar se é special property
			// TODO: verificar se existe ou não
			// TODO: verificar propriedades default... Tweener?
			// TODO: handleError
			// TODO: levar timeScale em consideração (?)
		}

		public function update(): Boolean {
			//
			
			if (!Boolean(scope)) return false;

			var isOver:Boolean = false;		// Whether or not it's over the update time
			var mustUpdate:Boolean;			// Whether or not it should be updated (skipped if false)
	
			var nv:Number;					// New value for each property
	
			var t:Number;					// current time (frames, seconds)
			//var b:Number;					// beginning value
			//var c:Number;					// change in value
			//var d:Number; 					// duration (frames, seconds)
	
			var pName:String;				// Property name, used in loops
	
			// Shortcut stuff for speed
			var cTime:Number = getCurrentTime();
			var tProperty:Object;			// Property being checked

			if (cTime >= timeStart) {
				// Can start/play the tween
	
				// It's a normal transition tween

				mustUpdate = skipUpdates < 1 || updatesSkipped >= skipUpdates;

				if (cTime >= timeComplete) {
					isOver = true;
					mustUpdate = true;
				}

				if (!started) {
					// First update, read all default values (for proper filter tweening)
					if (Boolean(onStart)) {
						try {
							onStart.apply(onStartScope, onStartParams);
						} catch(e:Error) {
							//handleError(this, e, "onStart");
						}
					}
					var pv:Number;
					for (pName in properties) {
						//if (properties[pName].isSpecialProperty) {
							/*
							// It's a special property, tunnel via the special property function
							if (Boolean(_specialPropertyList[pName].preProcess)) {
								tTweening.properties[pName].valueComplete = _specialPropertyList[pName].preProcess(tScope, _specialPropertyList[pName].parameters, tTweening.properties[pName].originalValueComplete, tTweening.properties[pName].extra);
							}
							pv = _specialPropertyList[pName].getValue(tScope, _specialPropertyList[pName].parameters, tTweening.properties[pName].extra);
							*/
						//} else {
							// Directly read property
							pv = scope[pName];
						//}
						properties[pName].valueStart = isNaN(pv) ? properties[pName].valueComplete : pv;
						properties[pName].valueChange = properties[pName].valueComplete - properties[pName].valueStart;
					}
					mustUpdate = true;
					started = true;
				}

				if (mustUpdate) {
					for (pName in properties) {
						tProperty = properties[pName];

						if (isOver) {
							// Tweening time has finished, just set it to the final value
							nv = tProperty.valueComplete;
						} else {
							//if (tProperty.hasModifier) {
								// Modified
								/*
								t = cTime - tTweening.timeStart;
								d = tTweening.timeComplete - tTweening.timeStart;
								nv = tTweening.transition(t, 0, 1, d, tTweening.transitionParams);
								nv = tProperty.modifierFunction(tProperty.valueStart, tProperty.valueComplete, nv, tProperty.modifierParameters);
								*/
							//} else {
								// Normal update
								// FUTURE:
								t = (cTime - timeStart) / timeDuration;
								nv = transition(t, transitionParams);
								nv *= tProperty.valueChange; // tProperty.valueComplete - tProperty.valueStart;
								nv += tProperty.valueStart;
								//t = cTime - timeStart;
								//b = tProperty.valueStart;
								//c = tProperty.valueComplete - tProperty.valueStart;
								//d = timeComplete - timeStart;
								//nv = transition(t, b, c, d, transitionParams);
							//}
						}

//						if (rounded) nv = Math.round(nv);

						//if (tProperty.isSpecialProperty) {
							/*
							// It's a special property, tunnel via the special property method
							_specialPropertyList[pName].setValue(tScope, nv, _specialPropertyList[pName].parameters, tTweening.properties[pName].extra);
							*/
						//} else {
							// Directly set property
							scope[pName] = nv;
						//}
					}

					updatesSkipped = 0;

					if (Boolean(onUpdate)) {
						try {
							onUpdate.apply(onUpdateScope, onUpdateParams);
						} catch(e:Error) {
							//handleError(this, e, "onUpdate");
						}
					}
				} else {
					updatesSkipped++;
				}
	
				if (isOver && Boolean(onComplete)) {
					try {
						onComplete.apply(onCompleteScope, onCompleteParams);
					} catch(e:Error) {
						//handleError(this, e, "onComplete");
					}
				}

				return (!isOver);
			}
	
			// On delay, hasn't started, so returns true
			return (true);
		}

		public function dispose(): void {
			//
		}
		

		public function updateCache(): void {
			timeDuration = timeComplete - timeStart;
		}

		// ==================================================================================================================================
		// ACESSOR functions ----------------------------------------------------------------------------------------------------------------

		public function get delay(): Number {
			return (timeStart - timeCreated) / (_useFrames ? 1 : 1000);
		}

		public function set delay(p_value:Number): void {
			timeStart = timeCreated + (p_value * (_useFrames ? 1 : 1000));
			updateCache();
		}

		public function get time(): Number {
			return (timeComplete - timeStart) / (_useFrames ? 1 : 1000);
		}

		public function set time(p_value:Number): void {
			timeComplete = timeStart + (p_value * (_useFrames ? 1 : 1000));
			updateCache();
		}

		public function get useFrames(): Boolean {
			return _useFrames;
		}

		public function set useFrames(p_value:Boolean): void {
			var tDelay:Number = delay;
			var tTime:Number = time;
			_useFrames = p_value;
			timeStart = getCurrentTime();
			delay = tDelay;
			time = tTime;
		}

		public function get paused(): Boolean {
			return _paused;
		}

		public function set paused(p_value:Boolean): void {
			if (p_value == _paused) return;
			_paused = p_value;
			if (paused) {
				// pause
			} else {
				// resume
			}
		}

		// ==================================================================================================================================
		// OTHER functions ------------------------------------------------------------------------------------------------------------------

		protected function getCurrentTime(): Number {
			return _useFrames ? Tweener.currentTimeFrame : Tweener.currentTime;
		}

		/**
		 * Checks if p_obj "inherits" properties from other objects, as set by the "base" property. Will create a new object, leaving others intact.
		 * o_bj.base can be an object or an array of objects. Properties are collected from the first to the last element of the "base" filed, with higher
		 * indexes overwritting smaller ones. Does not modify any of the passed objects, but makes a shallow copy of all properties.
		 *
		 * @param		p_obj		Object				Object that should be tweened: a movieclip, textfield, etc.. OR an array of objects
		 * @return					Object				A new object with all properties from the p_obj and p_obj.base.
		 */
		public static function makePropertiesChain(p_obj : Object) : Object {
			// Is this object inheriting properties from another object?
			var baseObject : Object = p_obj.base;
			if(baseObject){
				// object inherits. Are we inheriting from an object or an array
				var chainedObject : Object = {};
				var chain : Object;
				if (baseObject is Array){
					// Inheritance chain is the base array
					chain = [];
					// make a shallow copy
					for (var k : Number = 0 ; k< baseObject.length; k++) chain.push(baseObject[k]);
				}else{
					// Only one object to be added to the array
					chain = [baseObject];
				}
				// add the final object to the array, so it's properties are added last
				chain.push(p_obj);
				var currChainObj : Object;
				// Loops through each object adding it's property to the final object
				var len : Number = chain.length;
				for(var i : Number = 0; i < len ; i ++){
					if(chain[i]["base"]){
						// deal with recursion: watch the order! "parent" base must be concatenated first!
						currChainObj = concatObjects( makePropertiesChain(chain[i]["base"] ), chain[i]);
					}else{
						currChainObj = chain[i] ;
					}
					chainedObject = concatObjects(chainedObject, currChainObj );
				}
				if( chainedObject["base"]){
				    delete chainedObject["base"];
				}
				return chainedObject;
			}else{
				// No inheritance, just return the object it self
				return p_obj;
			}
		}

	}
	
	

	
}
