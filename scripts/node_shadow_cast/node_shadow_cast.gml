function Node_Shadow_Cast(_x, _y, _group = -1) : Node_Processor(_x, _y, _group) constructor {
	name = "Cast shadow";
	
	shader = sh_shadow_cast;
	uniform_dim   = shader_get_uniform(shader, "dimension");
	uniform_lpos  = shader_get_uniform(shader, "lightPos");
	uniform_prad  = shader_get_uniform(shader, "pointLightRadius");
	uniform_lrad  = shader_get_uniform(shader, "lightRadius");
	uniform_lden  = shader_get_uniform(shader, "lightDensity");
	uniform_ltyp  = shader_get_uniform(shader, "lightType");
	uniform_lamb  = shader_get_uniform(shader, "lightAmb");
	uniform_lclr  = shader_get_uniform(shader, "lightClr");
	uniform_sol   = shader_get_uniform(shader, "renderSolid");
	uniform_solid = shader_get_sampler_index(shader, "solid");
	
	inputs[| 0] = nodeValue(0, "Background", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 1] = nodeValue(1, "Solid", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 2] = nodeValue(2, "Light Position", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { 
			var _surf = inputs[| 0].getValue();
			if(is_array(_surf) && array_length(_surf) == 0)
				return [1, 1];
				
			if(is_array(_surf))
				_surf = _surf[0];
				
			if(!is_surface(_surf))
				return [1, 1];
			
			return [surface_get_width(_surf), surface_get_height(_surf)];
		}, VALUE_UNIT.reference);
		
	inputs[| 3] = nodeValue(3, "Soft light radius", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider, [0, 2, 0.01]);
	
	inputs[| 4] = nodeValue(4, "Light density", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 1)
		.setDisplay(VALUE_DISPLAY.slider, [1, 16, 1]);
	
	inputs[| 5] = nodeValue(5, "Light type", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, ["Point", "Sun"]);
	
	inputs[| 6] = nodeValue(6, "Ambient color", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, c_grey);
	
	inputs[| 7] = nodeValue(7, "Light color", self, JUNCTION_CONNECT.input, VALUE_TYPE.color, c_white);
	
	inputs[| 8] = nodeValue(8, "Light radius", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 16);
	
	inputs[| 9] = nodeValue(9, "Render solid", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
		
	outputs[| 0] = nodeValue(0, "Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, PIXEL_SURFACE);
	
	input_display_list = [
		["Surface",	false], 0, 1, 
		["Light",	false], 5, 8, 2, 3, 4, 
		["Render",	false], 7, 6, 9, 
	];
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) {
		inputs[| 2].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
		
		var _type = current_data[5];
		if(_type == 0) {
			var pos = current_data[2];
			var px = _x + pos[0] * _s;
			var py = _y + pos[1] * _s;
			
			inputs[| 8].drawOverlay(active, px, py, _s, _mx, _my, _snx, _sny, 0, 1 / 4, THEME.anchor_scale_hori);
		}
	}
	
	static process_data = function(_outSurf, _data, _output_index, _array_index) {
		var _bg    = _data[0];
		var _solid = _data[1];
		var _pos   = _data[2];
		var _rad   = _data[3];
		var _den   = _data[4];
		var _type  = _data[5];
		var _lamb  = _data[6];
		var _lclr  = _data[7];
		var _lrad  = _data[8];
		var _sol   = _data[9];
		
		inputs[| 8].setVisible(_type == 0);
		
		if(!is_surface(_bg)) return _outSurf;
		if(!is_surface(_solid)) return _outSurf;
		
		surface_set_target(_outSurf);
		draw_clear_alpha(0, 0);
		BLEND_OVER
		
		shader_set(shader);
			shader_set_uniform_f(uniform_dim, surface_get_width(_bg), surface_get_height(_bg));
			shader_set_uniform_f_array(uniform_lpos, _pos);
			shader_set_uniform_f_array(uniform_lamb, colToVec4(_lamb));
			shader_set_uniform_f_array(uniform_lclr, colToVec4(_lclr));
			shader_set_uniform_f(uniform_lrad, _rad);
			shader_set_uniform_f(uniform_prad, _lrad);
			shader_set_uniform_f(uniform_lden, _den);
			shader_set_uniform_i(uniform_ltyp, _type);
			shader_set_uniform_i(uniform_sol, _sol);
			texture_set_stage(uniform_solid, surface_get_texture(_solid));
			draw_surface_safe(_bg, 0, 0);
		shader_reset();
		
		BLEND_NORMAL
		surface_reset_target();
		
		return _outSurf;
	}
}