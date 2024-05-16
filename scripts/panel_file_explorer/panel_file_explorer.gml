enum FILE_EXPLORER_VIEW {
	list,
	grid
}

global.__temp_fileMap = {}

function ExpCreateFile(path) {
	INLINE
	if(struct_has(global.__temp_fileMap, path)) return global.__temp_fileMap[$ path];
	
	var f;
	
	if(directory_exists(path)) 
		f = new ExpDir(path);
	else 
		f = new ExpFile(path);
	
	global.__temp_fileMap[$ path] = f;
	return f;
}

function ExpFile(path) constructor {
	self.path = string_trim(path, [ "/", "\\" ]);
	name = filename_name_only(path);
	ext  = string_lower(filename_ext(path));
	
	load_thumb = false;
	thumbnail  = noone;
	th_w = 1;
	th_h = 1;
	
	static getThumbnail = function() {
		if(thumbnail == -1) 
			return noone;
		else if(thumbnail != noone)
			return thumbnail;
		
		thumbnail = -1;
		switch(ext) {
			case ".png" :
			case ".jpg" :
				thumbnail = sprite_add(path, 0, 0, 0, 0, 0);
				if(thumbnail) {
					load_thumb = true;
					th_w = sprite_get_width(thumbnail);
					th_h = sprite_get_height(thumbnail);
					sprite_set_offset(thumbnail, th_w / 2, th_h / 2);
				}
				break;
				
			case ".pxc":
			case ".pxcc":
				thumbnail = THEME.icon_64;
				th_w = 64;
				th_h = 64;
				break;
		}
		
		return thumbnail;
	}
	
	static destroy = function() {
		if(load_thumb) sprite_delete(thumbnail);
	}
}

function ExpDir(path) : ExpFile(path) constructor {
	directories = [];
	files       = [];
	
	open = -1; 
	
	static getContent = function() {
		directories = [];
		files       = [];
		
		if(!directory_exists(path)) return;
		
		var f = file_find_first(path + "\\*", fa_directory);
		while (f != "") {
			var _fp = $"{path}\\{f}";
			if(directory_exists(_fp))
		    	array_push(directories, ExpCreateFile(_fp));
		    f = file_find_next();
		}
		
		file_find_close();
		var f = file_find_first(path + "\\*", fa_none);
		while (f != "") {
			var _fp = $"{path}\\{f}";
			if(file_exists(_fp) && !directory_exists(_fp))
		    	array_push(files, ExpCreateFile(_fp));
		    f = file_find_next();
		}
		
		file_find_close();
		
		return self;
	}
	
	static destroy = function() {
		array_foreach(directories, function(dir) { dir.destroy(); return true; });
		array_foreach(files,       function(fil) { fil.destroy(); return true; });
	}
}

function ExpRoot() constructor {
	name = "Computer";
	directories = [];
	files       = [];
	
	open = -1; 
	
	static getContent = function() {
		directories = [];
		for(var i = 0; i < 26; i++) {
			var _dr = $"{chr(ord("A") + i)}:";
			if(directory_exists(_dr))
				array_push(directories, new ExpDir(_dr));
		}
	} getContent();
	
	static destroy = function() {
		array_foreach(directories, function(dir) { dir.destroy(); return true; });
	}
}

function Panel_File_Explorer() : PanelContent() constructor {
	title = "File Explorer";
	w = ui(320);
	h = ui(540);
	auto_pin = true;
	
	fileMap  = {};
	global.__temp_fileMap = fileMap;
	
	rootFile = noone;
	function setRoot(_root = "") {
		if(rootFile)
			rootFile.destroy();
		
		if(_root != "" && directory_exists(_root)) {
			root = _root;
			rootFile = new ExpDir(root).getContent();
			
			PREFERENCES.file_explorer = root;
			return;
		}
		
		rootFile  = new ExpRoot();
		root = "";
		
		PREFERENCES.file_explorer = root;
		
	} setRoot(PREFERENCES.file_explorer);
	
	scroll_y     = 0;
	scroll_y_to  = 0;
	scroll_y_max = 0;
	
	item_height  = ui(20);
	
	cntPad  = ui(4);
	padding = ui(8);
	top_bar = ui(44);
	
	tb_root = new textBox(TEXTBOX_INPUT.text, function(val) {
		setRoot(val);
	});
	
	file_selectings = [];
	file_hovering   = noone;
	
	file_dragging   = false;
	file_drag_mx    = 0;
	file_drag_my    = 0;
	
	frame_dragging  = false;
	frame_drag_mx   = false;
	frame_drag_my   = false;
	
	path_dragging   = -1;
	
	contentPane = new scrollPane(w - padding - padding - cntPad * 2, h - padding - top_bar - cntPad * 2, function(_y, _m, _r) {
		draw_clear_alpha(COLORS.panel_bg_clear, 0);
		
		if(frame_dragging) file_selectings = [];
		
		file_hovering   = noone;
		var _h = drawDir(rootFile, 0, _y, contentPane.surface_w, _m);
		
		if(frame_dragging) draw_sprite_stretched_points_clamp(THEME.ui_selection, 0, frame_drag_mx, frame_drag_my, _m[0], _m[1], COLORS._main_accent);
			
		if(mouse_press(mb_left, pFOCUS)) {
			if(file_hovering == noone) {
				file_selectings = [];
				frame_dragging  = true;
				frame_drag_mx   = _m[0];
				frame_drag_my   = _m[1];
				
			} else {	
				if(!array_exists(file_selectings, file_hovering))
					file_selectings = [ file_hovering ];
				path_dragging = -1;
				file_dragging = true;
				file_drag_mx  = mouse_mx;
				file_drag_my  = mouse_my;
			}
		}
		
		if(mouse_release(mb_left)) frame_dragging = false;
		
		if(file_dragging) {
			if(path_dragging == -1 && point_distance(file_drag_mx, file_drag_my, mouse_mx, mouse_my) > 8) {
				path_dragging = [];
				
				for (var i = 0, n = array_length(file_selectings); i < n; i++)
					path_dragging[i] = file_selectings[i].path;
			}
			
			if(mouse_release(mb_left)) {
				if(path_dragging != -1 && !pHOVER)
					o_main.load_file_path(path_dragging);
				
				file_dragging = false;	
				path_dragging = -1;
			}
		}
		
		return _h;
		
	} );
	
	
	function onResize() { #region
		initSize();
		
		contentPane.resize(w - padding - padding - cntPad * 2, h - padding - top_bar - cntPad * 2);
	} #endregion
	
	
	function drawDir(dirObject, _x, _y, _w, _m) {
		var _h  = 0;
		var _sy = _y;
		
		draw_set_text(f_p2, fa_left, fa_top, COLORS._main_text);
		var _ith = line_get_height() + ui(4);
		
		for (var i = 0, n = array_length(dirObject.directories); i < n; i++) {
			var _dir = dirObject.directories[i];
			
			var _px  = _x  + ui(2);
			var _py  = _sy + ui(2);
			var _pw  = _w  - ui(4);
			var _ph  = _ith;
			
			var _ind = 0;
			var _ppw = _pw;
			
			if(point_in_rectangle(_m[0], _m[1], _px, _py, _px + _pw, _py + _ph)) {
				if(buttonInstant(THEME.button_hide, _px + _ppw - _ph, _py, _ph, _ph, _m, pFOCUS, pHOVER, "", THEME.path_open_20) == 2) {
					setRoot(_dir.path);
				}
				_ppw -= _ph + ui(4);
			}
			
			if(contentPane.hover && point_in_rectangle(_m[0], _m[1], _px, _py, _px + _ppw, _py + _ph)) {
				file_hovering = _dir;
				_ind = 3;
				
				if(mouse_press(mb_left)) {
					if(_dir.open == -1)
						_dir.getContent();
					_dir.open = !_dir.open;
				}
			}
			
			draw_sprite_stretched(THEME.ui_panel_bg, _ind, _px, _py, _ppw, _ph);
			
			var _tx = _px + ui(2);
			var _ty = _py + ui(2);
			
			draw_sprite_ext(THEME.arrow, _dir.open? 3 : 0, _tx + _ph / 2, _py + _ph / 2, 1, 1, 0, COLORS._main_icon, 1);
			_tx += _ph + ui(2);
			draw_set_color(merge_color(COLORS._main_text, COLORS._main_text_sub, 0.5));
			draw_text_add(_tx, _ty, _dir.name);
			
			_h  += _ith + ui(2);
			_sy += _ith + ui(2);
			
			if(_dir.open) {
				var _drh = drawDir(_dir, _x + ui(8), _sy, _w - ui(8), _m);
				_h  += _drh;
				_sy += _drh;
			}
		}
		
		for (var i = 0, n = array_length(dirObject.files); i < n; i++) {
			var _fil = dirObject.files[i];
			
			var _px  = _x  + ui(2);
			var _py  = _sy + ui(2);
			var _pw  = _w  - ui(4);
			var _ph  = _ith;
			
			var _tw = ui(4) + _ph + string_width(_fil.name) + ui(8);
			
			if(frame_dragging && rectangle_in_rectangle(_px, _py, _px + _tw, _py + _ph, frame_drag_mx, frame_drag_my, _m[0], _m[1]))
				array_push(file_selectings, _fil);
			
			var _sel = array_exists(file_selectings, _fil);
			
			var _tx = _px + ui(2);
			var _ty = _py + ui(2);
			var _th = _fil.getThumbnail();
			
			draw_set_color(c_white);
			gpu_set_colorwriteenable(1, 1, 1, 0);
			draw_rectangle(_px, _py, _px + _tw, _py + _ph, false);
			gpu_set_colorwriteenable(1, 1, 1, 1);
			
			if(_sel) draw_sprite_stretched_ext(THEME.ui_panel_bg, 4, _px, _py, _tw, _ph, merge_color(COLORS._main_icon_dark, COLORS._main_icon, 0.3), 1);
			
			if(contentPane.hover && point_in_rectangle(_m[0], _m[1], _px, _py, _px + _tw, _py + _ph)) {
				if(!mouse_click(mb_left)) {
					draw_sprite_stretched_ext(THEME.ui_panel_fg, 1, _px, _py, _tw, _ph, COLORS._main_icon_light, 1);
					TOOLTIP = [ _th, "sprite" ];
				}
				
				file_hovering = _fil;
				
				if(mouse_press(mb_left) && key_mod_press(CTRL)) {
					if(_sel) array_remove(file_selectings, _fil);
					else     array_push(file_selectings, _fil);
				}
			}
			
			if(sprite_exists(_th)) {
				var _ths = min(1, (_ph - ui(4)) / _fil.th_w, (_ph - ui(4)) / _fil.th_h);
				draw_sprite_ext(_th, 0, _tx + _ph / 2, _py + _ph / 2, _ths, _ths, 0, c_white, 1);
			}
			_tx += _ph + ui(4);
			
			draw_set_color(COLORS._main_text);
			draw_text_add(_tx, _ty, _fil.name);
			
			_h  += _ith + ui(2);
			_sy += _ith + ui(2);
		}
		
		return _h;
	}
	
	function drawContent(panel) {
		draw_clear_alpha(COLORS.panel_bg_clear, 0);
		
		var pad   = padding;
		var cnt_x = pad;
		var cnt_y = top_bar;
		var cnt_w = w - pad - cnt_x;
		var cnt_h = h - pad - cnt_y;
			
		draw_sprite_stretched(THEME.ui_panel_bg, 1, cnt_x, cnt_y, cnt_w, cnt_h);
		
		var bs = top_bar - pad - ui(8);
		if(buttonInstant(THEME.button_hide, pad, pad, bs, bs, [mx, my], pFOCUS, pHOVER, "Go up", THEME.arrow, 1, root != ""? COLORS._main_icon : COLORS._main_icon_dark) == 2)
			if(root != "") setRoot(filename_dir(root));
		
		var tb_x = cnt_x + ui(32);
		var tb_y = pad;
		var tb_w = w - pad - tb_x;
		var tb_h = top_bar - pad - ui(8);
		
		tb_root.setFocusHover(pFOCUS, pHOVER);
		tb_root.font = f_p2;
		tb_root.draw(tb_x, tb_y, tb_w, tb_h, root, [mx, my]);
		
		contentPane.setFocusHover(pFOCUS, pHOVER);
		contentPane.draw(cnt_x + cntPad, cnt_y + cntPad, mx - cnt_x - cntPad, my - cnt_y - cntPad);
	}
	
	function drawGUI() {
		
		if(path_dragging != -1) {
			for (var i = 0, n = array_length(file_selectings); i < n; i++) {
				var f  = file_selectings[i];
				
				if(is_instanceof(f, ExpDir)) {
					draw_sprite_ext(THEME.folder_content, 0, mouse_mx + 20 + 8 * i, 
															 mouse_my + 20 + 8 * i, 
															 1, 1, 0, c_white, 1);
					
				} else if(is_instanceof(f, ExpDir)) {
					var _s = 64 / max(f.th_w, f.th_h);
					if(f.thumbnail) draw_sprite_ext(f.thumbnail, 0, mouse_mx + f.th_w * _s / 2 + 8 * i, 
																	mouse_my + f.th_h * _s / 2 + 8 * i, 
																	_s, _s, 0, c_white, 1);
				}
			}
		}
	}
	
}