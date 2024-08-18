function L_Turtle(x = 0, y = 0, ang = 90, w = 1, color = c_white, itr = 0) constructor {
	self.x     = x;
	self.y     = y;
	self.ang   = ang;
	self.w     = w;
	self.color = color;
	
	self.itr   = itr;
	
	static clone = function() { return new L_Turtle(x, y, ang, w, color, itr); }
}

function Node_Path_L_System(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name		= "L System";
	setDimension(96, 48);
	
	newInput(0, nodeValue_Float("Length", self, 8));
	
	newInput(1, nodeValue_Rotation("Angle", self, 45));
		
	newInput(2, nodeValue_Vec2("Starting position", self, [ DEF_SURF_W / 2, DEF_SURF_H / 2 ]));
	
	newInput(3, nodeValue_Int("Iteration", self, 4));
	
	newInput(4, nodeValue_Text("Starting rule", self, "", o_dialog_l_system));
	
	newInput(5, nodeValue_Text("End replacement", self, "", "Replace symbol of the last generated rule, for example a=F to replace all a with F. Use comma to separate different replacements."));
	
	newInput(6, nodeValue_Rotation("Starting Angle", self, 90));
	
	inputs[7] = nodeValue_Int("Seed", self, seed_random(6))
		.setDisplay(VALUE_DISPLAY._default, { side_button : button(function() { randomize(); inputs[7].setValue(seed_random(6)); }).setIcon(THEME.icon_random, 0, COLORS._main_icon) });
	
	static createNewInput = function() {
		var index = array_length(inputs);
		newInput(index + 0, nodeValue_Text("Name " + string(index - input_fix_len), self, "" ));
		newInput(index + 1, nodeValue_Text("Rule " + string(index - input_fix_len), self, "" ));
		
		return inputs[index + 0];
	}
	
	setDynamicInput(2, false);
	if(!LOADING && !APPENDING) createNewInput();
	
	outputs[0] = nodeValue_Output("Path", self, VALUE_TYPE.pathnode, self);
	
	rule_renderer = new Inspector_Custom_Renderer(function(_x, _y, _w, _m, _hover, _focus) {
		rule_renderer.x = _x;
		rule_renderer.y = _y;
		rule_renderer.w = _w;
		
		var hh = ui(8);
		var tx = _x + ui(32);
		var ty = _y + hh;
		
		var _tw = ui(64);
		var _th = TEXTBOX_HEIGHT + ui(4);
		
		for( var i = input_fix_len; i < array_length(inputs); i += data_length ) {
			var _name = inputs[i + 0];
			var _rule = inputs[i + 1];
			
			draw_set_text(f_p1, fa_left, fa_top, COLORS._main_text_sub);
			draw_text_add(_x + ui(8), ty + ui(8), string((i - input_fix_len) / data_length));
			
			_name.editWidget.setFocusHover(_focus, _hover);
			_name.editWidget.draw(tx, ty, _tw, _th, _name.showValue(), _m, _name.display_type);
			
			draw_sprite_ui(THEME.arrow, 0, tx + _tw + ui(16), ty + _th / 2,,,, COLORS._main_icon);
			
			_rule.editWidget.setFocusHover(_focus, _hover);
			var wh = max(_th, _rule.editWidget.draw(tx + _tw + ui(32), ty, _w - (_tw + ui(8 + 24 + 32)), _th, _rule.showValue(), _m, _rule.display_type));
			
			ty += wh + ui(6);
			hh += wh + ui(6);
		}
		
		return hh;
	}, 
	function(parent = noone) {
		for( var i = input_fix_len; i < array_length(inputs); i += data_length ) {
			var _name = inputs[i + 0];
			var _rule = inputs[i + 1];
			
			_name.editWidget.register(parent);
			_rule.editWidget.register(parent);
		}
	});
	
	input_display_list = [
		["Origin",		false], 2, 6, 
		["Properties",  false], 0, 1, 7, 
		["Rules",		false], 3, 4, rule_renderer, 5, 
	];
	
	attributes.rule_length_limit = 10000;
	array_push(attributeEditors, "L System");
	array_push(attributeEditors, [ "Rule length limit", function() { return attributes.rule_length_limit; }, 
		new textBox(TEXTBOX_INPUT.number, function(val) { 
			attributes.rule_length_limit = val; 
			cache_data.start = "";
			triggerRender();
		}) ]);
	
	cache_data = {
		start     : "",
		rules     : {},
		end_rule  : "",
		iteration : 0,
		seed      : 0,
		result    : ""
	}
	
	static refreshDynamicInput = function() {
		var _l = [];
		
		for( var i = 0; i < input_fix_len; i++ )
			_l[i] = inputs[i];
		
		for( var i = input_fix_len; i < array_length(inputs); i += data_length ) {
			if(getInputData(i) != "") {
				array_push(_l, inputs[i + 0]);
				array_push(_l, inputs[i + 1]);
			} else {
				delete inputs[i + 0];	
				delete inputs[i + 1];	
			}
		}
		
		for( var i = 0; i < array_length(_l); i++ )
			_l[i].index = i;
		

		inputs = _l;
		
		createNewInput();
	}
	
	static onValueUpdate = function(index) {
		if(index > input_fix_len && !LOADING && !APPENDING) 
			refreshDynamicInput();
	}
	
	static drawOverlay = function(hover, active, _x, _y, _s, _mx, _my, _snx, _sny) {
		inputs[2].drawOverlay(hover, active, _x, _y, _s, _mx, _my, _snx, _sny);
		
		var _out = getSingleValue(0, preview_index, true);
		if(!is_struct(_out)) return;
		
		draw_set_color(COLORS._main_accent);
		for( var i = 0, n = array_length(_out.lines); i < n; i++ ) {
			var p0 = _out.lines[i][0];
			var p1 = _out.lines[i][1];
			
			var x0 = p0[0];
			var y0 = p0[1];
			var x1 = p1[0];
			var y1 = p1[1];
			
			x0 = _x + x0 * _s;
			y0 = _y + y0 * _s;
			x1 = _x + x1 * _s;
			y1 = _y + y1 * _s;
				
			draw_line(x0, y0, x1, y1);
		}
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	function Path_LSystem() constructor {
		lines          = [];
		current_length = 0;
		boundary       = new BoundingBox();
		
		static getLineCount		= function() { return array_length(lines); }
		static getSegmentCount	= function() { return 1; }
		
		static getLength		= function() { return current_length; }
		static getAccuLength	= function() { return [ 0, current_length ]; }
		
		static getWeightDistance = function (_dist, _ind = 0) {
			return getWeightRatio(_dist / current_length, _ind); 
		}
		
		static getWeightRatio = function (_rat, _ind = 0) {
			var _p0 = lines[_ind][0];
			var _p1 = lines[_ind][1];
			
			if(!is_array(_p0) || array_length(_p0) < 2) return 1;
			if(!is_array(_p1) || array_length(_p1) < 2) return 1;
			
			return lerp(_p0[2], _p1[2], _rat);
		}
		
		static getPointRatio = function(_rat, _ind = 0, out = undefined) {
			if(out == undefined) out = new __vec2(); else { out.x = 0; out.y = 0; }
			
			var _p0 = lines[_ind][0];
			var _p1 = lines[_ind][1];
			
			if(!is_array(_p0) || array_length(_p0) < 2) return out;
			if(!is_array(_p1) || array_length(_p1) < 2) return out;
			
			out.x  = lerp(_p0[0], _p1[0], _rat);
			out.y  = lerp(_p0[1], _p1[1], _rat);
			
			return out;
		}
		
		static getPointDistance = function(_dist, _ind = 0, out = undefined) { return getPointRatio(_dist / current_length, _ind, out); }
		
		static getBoundary	= function() { return boundary; }
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	static l_system = function(_start, _rules, _end_rule, _iteration, _seed) {
		if(isEqual(cache_data.rules, _rules, true)
			&& cache_data.start	     == _start
			&& cache_data.end_rule	 == _end_rule
			&& cache_data.iteration  == _iteration
			&& cache_data.seed	     == _seed) {
			
			return cache_data.result;
		}
		
		cache_data.start	 = _start;
		cache_data.rules	 = _rules;
		cache_data.end_rule	 = _end_rule;
		cache_data.iteration = _iteration;
		cache_data.seed		 = _seed;
		cache_data.result    = _start;
		
		_temp_s = "";
		
		for( var j = 1; j <= _iteration; j++ ) {
			_temp_s = "";
			
			string_foreach(cache_data.result, function(_ch, _) {
				if(!struct_has(cache_data.rules, _ch)) {
					_temp_s += _ch;
					return;
				}
				
				var _chr = cache_data.rules[$ _ch];
				_chr = array_safe_get_fast(_chr, irandom(array_length(_chr) - 1));
				
				_temp_s += _chr;
			})
			
			cache_data.result = _temp_s;
			if(string_length(cache_data.result) > attributes.rule_length_limit) {
				var _txt = $"L System: Rules length limit ({attributes.rule_length_limit}) reached.";
				logNode(_txt); noti_warning(_txt);
				break;
			}
		}
		
		var _es  = string_splice(_end_rule, ",");
		for( var i = 0, n = array_length(_es); i < n; i++ ) {
			var _sp = string_splice(_es[i], "=");
			if(array_length(_sp) == 2)
				cache_data.result = string_replace_all(cache_data.result, _sp[0], _sp[1]);
		}
		
		return cache_data.result;
	}
	
	__curr_path = noone;
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		
		var _len = _data[0];
		var _ang = _data[1];
		var _pos = _data[2];
		var _itr = _data[3];
		var _sta = _data[4];
		var _end = _data[5];
		var _san = _data[6];
		var _sad = _data[7];
		lineq    = ds_queue_create();
		
		random_set_seed(_sad);
		__curr_path = new Path_LSystem();
		__curr_path.current_length = _len;
		
		if(array_length(inputs) < input_fix_len + 2) return __curr_path;
		
		var rules = {};
		for( var i = input_fix_len; i < array_length(inputs); i += data_length ) {
			var _name = _data[i + 0];
			var _rule = _data[i + 1];
			if(_name == "") continue;
			
			if(!struct_has(rules, _name))
				rules[$ _name] = [ _rule ];
			else
				array_push(rules[$ _name], _rule);
		}
		
		l_system(_sta, rules, _end, _itr, _sad);
		itr    = _itr;
		ang    = _ang;
		len    = _len;
		st     = ds_stack_create();
		t      = new L_Turtle(_pos[0], _pos[1], _san);
		maxItr = 0;
		
		string_foreach(cache_data.result, function(_ch, _) {
			switch(_ch) {
				case "F": 
					var nx = t.x + lengthdir_x(len, t.ang);
					var ny = t.y + lengthdir_y(len, t.ang);
					
					ds_queue_enqueue(lineq, [ [ t.x, t.y, t.w, t.itr ], [ nx, ny, t.w, t.itr + 1 ] ]);
					
					t.x = nx;
					t.y = ny;
					t.itr++;
					maxItr = max(maxItr, t.itr);
					
					break;
					
				case "G": 
					t.x = t.x + lengthdir_x(len, t.ang);
					t.y = t.y + lengthdir_y(len, t.ang);
					break;
					
				case "f": 
					var nx = t.x + lengthdir_x(len * frac(itr), t.ang);
					var ny = t.y + lengthdir_y(len * frac(itr), t.ang);
					
					ds_queue_enqueue(lineq, [ [ t.x, t.y, t.w, t.itr ], [ nx, ny, t.w, t.itr + 1 ] ]);
					
					t.x = nx;
					t.y = ny;
					t.itr++;
					maxItr = max(maxItr, t.itr);
					break;
					
				case "+": t.ang += ang; break;
				case "-": t.ang -= ang; break;
				case "|": t.ang += 180; break;
				
				case "[": ds_stack_push(st, t.clone()); break;
				case "]": 
					if(ds_stack_empty(st)) noti_warning("L-system: Trying to pop an empty stack. Make sure that all close brackets ']' has a corresponding open bracket '['.");
				    else t = ds_stack_pop(st);
				    break;
				
				case ">": t.w += 0.1; break;
				case "<": t.w -= 0.1; break;
				
				// default : noti_warning($"L-system: Invalid rule '{_ch}'"); 
			}
		});
		
		ds_stack_destroy(st);
		
		__curr_path.boundary = new BoundingBox();
		__curr_path.lines    = array_create(ds_queue_size(lineq));
		
		var i = 0;
		var a = ds_queue_size(lineq);
		
		repeat(a) {
			var _l = ds_queue_dequeue(lineq);
			
			__curr_path.lines[i++] = _l;
			__curr_path.boundary.addPoint(_l[0][0], _l[0][1], _l[1][0], _l[1][1]);
		}
		
		ds_queue_destroy(lineq);
		
		return __curr_path;
	}
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) {
		var bbox = drawGetBbox(xx, yy, _s);
		draw_sprite_fit(s_node_path_l_system, 0, bbox.xc, bbox.yc, bbox.w, bbox.h);
	}
}