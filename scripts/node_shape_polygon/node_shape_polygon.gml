function Node_Shape_Polygon(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Draw Shape Polygon";
	batch_output = false;
	
	shapesArray = [ "Rectangle", "Ellipse", "Star", "Capsule", "Ring", "Arc", "Gear", "Cross" ];
	for( var i = 0, n = array_length(shapesArray); i < n; i++ ) 
		shapesArray[i] = new scrollItem(shapesArray[i], s_node_shape_poly_type, i);
		
	newInput(0, nodeValue_Dimension(self));
	
	newInput(1, nodeValue_Bool("Background", self, false));
	
	newInput(2, nodeValue_Color("Background color", self, c_black));
	
	newInput(3, nodeValue_Color("Shape color", self, c_white));
	
	newInput(4, nodeValue_Enum_Scroll("Shape", self,  0, shapesArray));
	
	inputs[5] = nodeValue_Vec2("Position", self, [ 0.5, 0.5 ])
		.setUnitRef(function(index) { return getDimension(index); }, VALUE_UNIT.reference);
	
	newInput(6, nodeValue_Rotation("Rotation", self, 0));
	
	inputs[7] = nodeValue_Vec2("Scale", self, [ 0.5, 0.5 ])
		.setUnitRef(function(index) { return getDimension(index); }, VALUE_UNIT.reference);
	
	inputs[8] = nodeValue_Int("Sides", self, 16)
		.setDisplay(VALUE_DISPLAY.slider, { range: [2, 64, 0.1] });
	
	inputs[9] = nodeValue_Float("Inner radius", self, 0.5)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[10] = nodeValue_Float("Radius", self, 0.5)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[11] = nodeValue_Int("Teeth", self, 6)
		.setDisplay(VALUE_DISPLAY.slider, { range: [3, 16, 0.1] });
	
	inputs[12] = nodeValue_Float("Teeth height", self, 0.2)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[13] = nodeValue_Float("Teeth taper", self, 0)
		.setDisplay(VALUE_DISPLAY.slider, { range: [-0.5, 0.5, 0.01] });
	
	newInput(14, nodeValue_Rotation_Range("Angle range", self, [ 0, 360 ]));
	
	newInput(15, nodeValue_Bool("Round cap", self, false));
	
	inputs[16] = nodeValue("Mesh", self, JUNCTION_CONNECT.input, VALUE_TYPE.mesh, noone)
		.setVisible(true, true);
		
	outputs[0] = nodeValue_Output("Surface out", self, VALUE_TYPE.surface, noone);
		
	outputs[1] = nodeValue_Output("Mesh", self, VALUE_TYPE.mesh, noone);
		
	outputs[2] = nodeValue_Output("Path", self, VALUE_TYPE.pathnode, noone);
	
	input_display_list = [ 16, 
		["Output", 		false], 0, 
		["Transform",	false], 5, 6, 7, 
		["Shape",		false], 4, 8, 9, 10, 11, 12, 13, 14, 15, 
		["Render",		 true],	3, 
		["Background",	 true, 1], 2, 
	];
	
	attribute_surface_depth();
	
	node_draw_transform_init();
	
	static drawOverlay = function(hover, active, _x, _y, _s, _mx, _my, _snx, _sny) {
		if(array_length(current_data) != array_length(inputs)) return;
		if(process_amount > 1) return;
		
		draw_set_color(c_grey);
		mesh.draw(_x, _y, _s);
		node_draw_transform_box(active, _x, _y, _s, _mx, _my, _snx, _sny, 5, 6, 7, true);
		
		draw_set_color(COLORS._main_accent);
		path.draw(_x, _y, _s);
	}
	
	static vertex_transform = function(_p, _pos, _rot) {
		var p = point_rotate(_p.x, _p.y, 0, 0, _rot);
		_p.x = _pos[0] + p[0];
		_p.y = _pos[1] + p[1];
		
		draw_vertex(_p.x, _p.y);
	}
	
	mesh = new Mesh();
	path = new PathSegment();
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		if(_output_index == 1) return mesh;
		if(_output_index == 2) return path;
		
		var _dim	= _data[0];
		var _bg		= _data[1];
		var _bgc	= _data[2];
		var _shc	= _data[3];
		var _shp	= _data[4];
		var _pos	= _data[5];
		var _rot	= _data[6];
		var _sca	= _data[7];
		var _side	= _data[8];
		var _inner	= _data[9];
		var _rad	= _data[10];
		var _teeth  = _data[11];
		var _thHei  = _data[12];
		var _thTap  = _data[13];
		var _aRan   = _data[14];
		var _cap    = _data[15];
		var _mesh   = _data[16];
		
		inputs[ 8].setVisible(_shp == 1 || _shp == 2 || _shp == 3 || _shp == 4 || _shp == 5);
		inputs[ 9].setVisible(_shp == 2 || _shp == 4 || _shp == 5 || _shp == 6 || _shp == 7);
		inputs[10].setVisible(_shp == 3);
		inputs[11].setVisible(_shp == 6);
		inputs[12].setVisible(_shp == 6);
		inputs[13].setVisible(_shp == 6);
		inputs[14].setVisible(_shp == 5);
		inputs[15].setVisible(_shp == 5);
		
		_outSurf = surface_verify(_outSurf, _dim[0], _dim[1], attrDepth());
		
		var data = {
			side:	_side,
			inner:	_inner,
			radius: _rad,
			radRan: _aRan,
			teeth:	_teeth,
			teethH: _thHei,
			teethT: _thTap,
			cap:    _cap,
		};
		
		surface_set_target(_outSurf);
			if(_bg) draw_clear(_bgc);
			else	DRAW_CLEAR
			
			draw_set_color(_shc);
			draw_primitive_begin(pr_trianglelist);
			
			outputs[2].setVisible(_mesh == noone);
			
			if(_mesh != noone) {
				for( var j = 0; j < array_length(_mesh.triangles); j++ ) {
					var tri = _mesh.triangles[j];
					var p0 = tri[0];
					var p1 = tri[1];
					var p2 = tri[2];
					
					draw_vertex(p0.x, p0.y);
					draw_vertex(p1.x, p1.y);
					draw_vertex(p2.x, p2.y);
				}
				
			} else {
				
				var shapeData = [];
			
				switch(array_safe_get_fast(shapesArray, _shp).name) {
					case "Rectangle" : shapeData = SHAPE_rectangle(_sca);		break;
					case "Ellipse"	 : shapeData = SHAPE_circle(_sca, data);	break;
					case "Star"		 : shapeData = SHAPE_star(_sca, data);		break;
					case "Capsule"	 : shapeData = SHAPE_capsule(_sca, data);	break;
					case "Ring"		 : shapeData = SHAPE_ring(_sca, data);		break;
					case "Arc"		 : shapeData = SHAPE_arc(_sca, data);		break;
					case "Gear"		 : shapeData = SHAPE_gear(_sca, data);		break;
					case "Cross"	 : shapeData = SHAPE_cross(_sca, data);		break;
					default: 
						draw_primitive_end();
						draw_set_alpha(1);
			
						surface_reset_target();
						return _outSurf;
				}
				
				var points  = shapeData[0];
				var segment = shapeData[1];
				
				for( var i = 0, n = array_length(segment); i < n; i++ ) {
					var _p = segment[i];
					var p = point_rotate(_p.x, _p.y, 0, 0, _rot);
					_p.x = _pos[0] + p[0];
					_p.y = _pos[1] + p[1];
				}
				path.setSegment(segment);
				
				var shapes = [];
				for( var i = 0, n = array_length(points); i < n; i++ ) {
					if(points[i].type == SHAPE_TYPE.points)
						shapes[i] = polygon_triangulate(points[i].points)[0];
						
					else if(points[i].type == SHAPE_TYPE.triangles)
						shapes[i] = points[i].triangles;
				}
				
				mesh.triangles = [];
				for( var i = 0, n = array_length(shapes); i < n; i++ ) {
					var triangles = shapes[i];
					
					for( var j = 0; j < array_length(triangles); j++ ) {
						var tri = triangles[j];
						
						vertex_transform(tri[0], _pos, _rot);
						vertex_transform(tri[1], _pos, _rot);
						vertex_transform(tri[2], _pos, _rot);
						
						array_push(mesh.triangles, tri);
					}
				}
				
				mesh.calcCoM();
			}
			draw_primitive_end();
			draw_set_alpha(1);
			
		surface_reset_target();
		
		return _outSurf;
	}
}