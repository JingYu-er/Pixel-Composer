function Node_MK_Brownian(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "MK Brownian";
	update_on_frame = true;
	
	inputs[| 0] = nodeValue("Surface", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, noone);
	
	inputs[| 1] = nodeValue("Sprite", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, noone);
	
	inputs[| 2] = nodeValue("Amount", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 10);
	
	inputs[| 3] = nodeValue("Area", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, AREA_DEF)
		.setDisplay(VALUE_DISPLAY.area);
	
	inputs[| 4] = nodeValue("Direction", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 45, 135, 0, 0 ] )
		.setDisplay(VALUE_DISPLAY.rotation_random);
	
	inputs[| 5] = nodeValue("Speed", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 1, 1 ])	
		.setDisplay(VALUE_DISPLAY.range);
	
	inputs[| 6] = nodeValue("Color", self, JUNCTION_CONNECT.input, VALUE_TYPE.gradient, new gradientObject(c_white));
	
	inputs[| 7] = nodeValue("Alpha", self, JUNCTION_CONNECT.input, VALUE_TYPE.curve, CURVE_DEF_11);
	
	inputs[| 8] = nodeValue("Seed", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, seed_random());
	
	inputs[| 9] = nodeValue("Angular speed", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ -45, 45 ])
		.setDisplay(VALUE_DISPLAY.range);
	
	inputs[| 10] = nodeValue("Angular acceleration", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ -2, 2 ])
		.setDisplay(VALUE_DISPLAY.range);
		
	inputs[| 11] = nodeValue("Turn", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false);
	
	outputs[| 0] = nodeValue("Output", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	input_display_list = [ new Inspector_Sprite(s_MKFX), 0, 8, 
		["Particles", false], 1, 
		["Spawn",     false], 3, 2, 
		["Movement",  false], 5, 4, 9, 
		["Smooth turn",   true, 11], 10, 
		["Render",    false], 6, 7, 
	];
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) {
		inputs[| 3].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
	}
	
	static getPosition = function(ind, t, _area, _sped, _dire, _dirs, _turn, _dira) { #region
		random_set_seed(ind);
		
		var _px = irandom_range(_area[0] - _area[2], _area[0] + _area[2]);
		var _py = irandom_range(_area[1] - _area[3], _area[1] + _area[3]);
		
		var spd = random_range(_sped[0], _sped[1]);
		var dir = angle_random_eval(_dire);
		var dis = random_range(_dirs[0], _dirs[1]);
		var dia = random_range(_dira[0], _dira[1]);
		
		repeat(t) {
			_px += lengthdir_x(spd, dir);
			_py += lengthdir_y(spd, dir);
			
			if(_turn) {
				var a = random_range(_dira[0], _dira[1]);
				dis += a;
			} else {
				dis = random_range(_dirs[0], _dirs[1]);
			}
			
			dir += dis;
		}
		
		return [ _px, _py ];
	} #endregion
	
	static update = function() { #region
		var _surf = getInputData(0);
		var _sprt = getInputData(1);
		var _amou = getInputData(2);
		var _area = getInputData(3);
		var _dire = getInputData(4);
		var _sped = getInputData(5);
		var _colr = getInputData(6);
		var _alph = getInputData(7);
		var _seed = getInputData(8);
		var _dirs = getInputData(9);
		var _dira = getInputData(10);
		var _turn = getInputData(11);
		
		var _sed = _seed;
		
		if(!is_surface(_surf)) return;
		
		var _outSurf = outputs[| 0].getValue();
		_outSurf = surface_verify(_outSurf, surface_get_width_safe(_surf), surface_get_height_safe(_surf));
		outputs[| 0].setValue(_outSurf);
		
		surface_set_target(_outSurf);
			DRAW_CLEAR
			BLEND_OVERRIDE
				draw_surface_safe(_surf);
			BLEND_ALPHA_MULP
			
				for( var i = 0; i < _amou; i++ ) {
					_sed += 100;
					
					var _lifs = irandom_seed(TOTAL_FRAMES, _sed);
					var _lif  = (_lifs + CURRENT_FRAME) % TOTAL_FRAMES;
						
					var _pos = getPosition(_sed, _lif, _area, _sped, _dire, _dirs, _turn, _dira);
					var _cc  = _colr.eval(_lifs / TOTAL_FRAMES);
					var _aa  = eval_curve_x(_alph, _lif / TOTAL_FRAMES);
					
					if(_sprt == noone) {
						draw_set_color(_cc);
						draw_set_alpha(_aa);
						draw_point(_pos[0], _pos[1]);
						draw_set_alpha(1);
					} else {
						var _p = _sprt;
						if(is_array(_p)) _p = array_safe_get(_p, irandom(array_length(_p) - 1));
						
						draw_surface_ext_safe(_p, _pos[0], _pos[1], 1, 1, 0, _cc, _aa);
					}
				}
			BLEND_NORMAL
		surface_reset_target();
	} #endregion
}