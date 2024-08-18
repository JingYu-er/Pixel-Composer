function Node_Local_Analyze(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Local Analyze";
	
	newInput(0, nodeValue_Surface("Surface in", self));
	
	newInput(1, nodeValue_Enum_Scroll("Algorithm", self,  0, [ "Average (Blur)", "Maximum", "Minimum" ]));
	
	inputs[2] = nodeValue_Float("Size", self, 1)
		.setDisplay(VALUE_DISPLAY.slider, { range: [ 1, 16, 0.1] });
	
	inputs[3] = nodeValue_Enum_Scroll("Oversample mode", self,  0, [ "Empty", "Clamp", "Repeat" ])
		.setTooltip("How to deal with pixel outside the surface.\n    - Empty: Use empty pixel\n    - Clamp: Repeat edge pixel\n    - Repeat: Repeat texture.");
	
	inputs[4] = nodeValue_Enum_Scroll("Shape", self,  0, [ new scrollItem("Square",  s_node_shape_rectangle, 0), 
												 new scrollItem("Circle",  s_node_shape_circle,    0), 
												 new scrollItem("Diamond", s_node_shape_misc, 0) ]);
		
	newInput(5, nodeValue_Surface("Mask", self));
	
	inputs[6] = nodeValue_Float("Mix", self, 1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	newInput(7, nodeValue_Bool("Active", self, true));
		active_index = 7;
	
	newInput(8, nodeValue_Toggle("Channel", self, 0b1111, { data: array_create(4, THEME.inspector_channel) }));
		
	__init_mask_modifier(5); // inputs 9, 10
	
	outputs[0] = nodeValue_Output("Surface out", self, VALUE_TYPE.surface, noone);
	
	input_display_list = [ 7, 8, 
		["Surfaces", true],	0, 5, 6, 9, 10, 
		["Effect",	false],	1, 2, 4,
	];
	
	attribute_surface_depth();
	attribute_oversample();
	
	static step = function() { #region
		__step_mask_modifier();
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		var _alg = _data[1];
		var _siz = _data[2];
		var _shp = _data[4];
		var _sam = struct_try_get(attributes, "oversample");
		
		surface_set_shader(_outSurf, sh_local_analyze);
			shader_set_f("dimension" , surface_get_dimension(_data[0]));
			shader_set_i("algorithm" , _alg);
			shader_set_f("size"      , _siz);
			shader_set_i("shape"     , _shp);
			shader_set_i("sampleMode", _sam);
			
			draw_surface_safe(_data[0]);
		surface_reset_shader();
		
		__process_mask_modifier(_data);
		_outSurf = mask_apply(_data[0], _outSurf, _data[5], _data[6]);
		_outSurf = channel_apply(_data[0], _outSurf, _data[8]);
		
		return _outSurf;
	}
}