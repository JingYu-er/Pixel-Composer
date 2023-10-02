enum ANIM_END_ACTION {
	loop,
	pingpong,
	destroy,
}

enum PARTICLE_BLEND_MODE {
	normal,
	alpha,
	additive
}

function __part(_node) constructor {
	seed    = irandom(99999);
	node    = _node;
	active  = false;
	surf    = noone;
	prevx   = 0;
	prevy   = 0;
	x       = 0;
	y       = 0;
	speedx  = 0;
	speedy  = 0;
	turning = 0;
	turnSpd = 0;
	
	drawx   = 0;
	drawy   = 0;
	drawrot = 0;
	drawsx  = 0;
	drawsy  = 0;
	
	accel   = 0;
	spVec   = [ 0, 0 ];
	
	//wig_psx = new wiggleMap(seed, 1, PROJECT.animator.frames_total);
	//wig_psy = new wiggleMap(seed, 1, PROJECT.animator.frames_total);
	
	//wig_scx = new wiggleMap(seed, 1, PROJECT.animator.frames_total);
	//wig_scy = new wiggleMap(seed, 1, PROJECT.animator.frames_total);
	
	//wig_rot = new wiggleMap(seed, 1, PROJECT.animator.frames_total);
	//wig_dir = new wiggleMap(seed, 1, PROJECT.animator.frames_total);
	
	boundary_data = -1;
	
	grav    = 0;
	gravDir = -90;
	gravX   = 0;
	gravY   = 0;
	
	scx   = 1;
	scy   = 1;
	sc_sx  = 1;
	sc_sy  = 1;
	sct   = CURVE_DEF_11;
	
	rot		= 0;
	follow	= false;
	rot_s	= 0;
	
	col      = -1;
	blend	 = c_white;
	alp      = 1;
	alp_draw = alp;
	alp_fade = 0;
	
	life       = 0;
	life_total = 0;
	step_int   = 0;
	
	anim_speed = 1;
	anim_end   = ANIM_END_ACTION.loop;
	
	ground			= false;
	ground_y		= 0;
	ground_bounce	= 0;
	ground_friction = 1;
	
	static create = function(_surf, _x, _y, _life) { #region
		active	= true;
		surf	= _surf;
		x	= _x;
		y	= _y;
		
		prevx  = undefined;
		prevy  = undefined;
		
		life = _life;
		life_total = life;
		node.onPartCreate(self);
	} #endregion
	
	static setPhysic = function(_sx, _sy, _ac, _g, _gDir, _turn, _turnSpd) { #region
		speedx  = _sx;
		speedy  = _sy;
		accel   = _ac;
		grav    = _g;
		gravDir = _gDir;
		gravX   = lengthdir_x(grav, gravDir);
		gravY   = lengthdir_y(grav, gravDir);
		
		turning = _turn;
		turnSpd = _turnSpd;
	
		spVec[0] = point_distance(0, 0, speedx, speedy);
		spVec[1] = point_direction(0, 0, speedx, speedy);
	} #endregion
	
	static setWiggle = function(wiggle_maps) { #region
		//wig_psx.check(_wig_pos[0], _wig_pos[1], seed + 10);
		//wig_psy.check(_wig_pos[0], _wig_pos[1], seed + 20);
		//wig_rot.check(_wig_rot[0], _wig_rot[1], seed + 30);
		//wig_scx.check(_wig_sca[0], _wig_sca[1], seed + 40);
		//wig_scy.check(_wig_sca[0], _wig_sca[1], seed + 50);
		//wig_dir.check(_wig_dir[0], _wig_dir[1], seed + 60);
		
		wig_psx = wiggle_maps.wig_psx;
		wig_psy = wiggle_maps.wig_psy;
		wig_rot = wiggle_maps.wig_rot;
		wig_scx = wiggle_maps.wig_scx;
		wig_scy = wiggle_maps.wig_scy;
		wig_dir = wiggle_maps.wig_dir;
	} #endregion
	
	static setGround = function(_ground, _ground_offset, _ground_bounce, _ground_frict) { #region
		ground			= _ground;
		ground_y		= y + _ground_offset;
		ground_bounce	= _ground_bounce;
		ground_friction	= clamp(1 - _ground_frict, 0, 1);
	} #endregion
	
	static setTransform = function(_scx, _scy, _sct, _rot, _rots, _follow) { #region
		sc_sx = _scx;
		sc_sy = _scy;
		sct   = _sct;
		
		rot   = _rot;
		rot_s = _rots;
		follow = _follow;
	} #endregion
	
	static setDraw = function(_col, _blend, _alp, _fade) { #region
		col      = _col;
		blend	 = _blend;
		alp      = _alp;
		alp_draw = _alp;
		alp_fade = _fade;
	} #endregion
	
	static kill = function() { #region
		active = false;
		
		node.onPartDestroy(self);
	} #endregion
	
	static step = function() { #region
		if(!active) return;
		x += speedx;
		
		random_set_seed(seed + life);
		
		if(ground && y + speedy > ground_y) {
			y = ground_y;
			speedy = -speedy * ground_bounce;
			
			if(abs(speedy) < 0.1)
				speedx *= ground_friction;
		} else
			y += speedy;
		
		var dirr = point_direction(0, 0, speedx, speedy);
		var diss = point_distance(0, 0, speedx, speedy);
		diss = max(0, diss + accel);
		
		if(speedx != 0 || speedy != 0) {
			dirr += wig_dir.get(seed + life);
			
			if(turning != 0) {
				var trn = turnSpd? turning * diss : turning;
				dirr += trn
			}
		}
		
		speedx = lengthdir_x(diss, dirr) + gravX;
		speedy = lengthdir_y(diss, dirr) + gravY;
		
		if(follow)  rot = spVec[1];
		else        rot += rot_s;
		
		if(step_int > 0 && safe_mod(life, step_int) == 0) 
			node.onPartStep(self);
		if(life-- < 0) kill();
		
		if(prevx != undefined) {
			spVec[0] = point_distance(prevx, prevy, x, y);
			spVec[1] = point_direction(prevx, prevy, x, y);
		}
		
		prevx = x;
		prevy = y;
		
		drawx   = x;
		drawy   = y;
		drawrot = rot;
		drawsx  = sc_sx;
		drawsy  = sc_sy;
		
		drawx   += wig_psx.get(seed + life);
		drawy   += wig_psy.get(seed + life);
		drawrot += wig_rot.get(seed + life);
		drawsx  += wig_scy.get(seed + life);
		drawsy  += wig_scy.get(seed + life);
	} #endregion
	
	static draw = function(exact, surf_w, surf_h) { #region
		var ss = surf;
		if(is_array(surf)) {
			var ind = abs(round((life_total - life) * anim_speed));
			var len = array_length(surf);
			
			switch(anim_end) {
				case ANIM_END_ACTION.loop: 
					ss = surf[safe_mod(ind, len)];
					break;
				case ANIM_END_ACTION.pingpong:
					var ping = safe_mod(ind, (len - 1) * 2 + 1); 
					ss = surf[ping >= len? (len - 1) * 2 - ping : ping];
					break;
				case ANIM_END_ACTION.destroy:
					if(ind >= len)	return;
					else			ss = surf[ind];
					break;
			}
		}
		
		var surface = node.surface_cache[$ ss];
		//print($"VFX: {surface} ({is_surface(surface)})")
		if(!is_surface(surface)) return;
		
		var lifeRat = 1 - life / life_total;
		var scCurve = sct.get(lifeRat);
		scx   = drawsx * scCurve;
		scy   = drawsy * scCurve;
		
		var _xx, _yy;
		var s_w = surface_get_width_safe(surface) * scx;
		var s_h = surface_get_height_safe(surface) * scy;
		
		if(boundary_data == -1) {
			var _pp = point_rotate(-s_w / 2, -s_h / 2, 0, 0, rot);
			_xx = drawx + _pp[0];
			_yy = drawy + _pp[1];
		} else {
			var ww = boundary_data[2] + boundary_data[0];
			var hh = boundary_data[3] + boundary_data[1];
			
			var cx = (boundary_data[0] + boundary_data[2]) / 2;
			var cy = (boundary_data[1] + boundary_data[3]) / 2;
			
			var _pp = point_rotate(-cx, -cy, 0, 0, rot);
			
			_xx = drawx + cx + _pp[0] * scx;
			_yy = drawy + cy + _pp[1] * scy;
		}
		
		if(exact) {
			_xx = round(_xx);
			_yy = round(_yy);
		}
		
		var x0 = _xx - s_w * 1.5;
		var y0 = _yy - s_h * 1.5;
		var x1 = _xx + s_w * 1.5;
		var y1 = _yy + s_h * 1.5;
		
		if(x0 > surf_w || y0 > surf_h || x1 < 0 || y1 < 0) return; //culling
		
		var cc = (col == -1)? c_white : col.eval(lifeRat);
		if(blend != c_white) cc = colorMultiply(blend, cc);
		alp_draw = alp * alp_fade.get(lifeRat);
		
		draw_surface_ext_safe(surface, _xx, _yy, scx, scy, drawrot, cc, alp_draw);
	} #endregion
	
	static getPivot = function() { #region
		if(boundary_data == -1) 
			return [x, y];
		
		var ww = (boundary_data[2] - boundary_data[0]) * scx;
		var hh = (boundary_data[3] - boundary_data[1]) * scy;
		var cx = x + boundary_data[0] + ww / 2;
		var cy = y + boundary_data[1] + hh / 2;
		
		return [cx, cy];
	} #endregion
}

#region helper
	#macro UPDATE_PART_FORWARD static updateParticleForward = function() {		\
		var pt = outputs[| 0];													\
		for( var i = 0; i < ds_list_size(pt.value_to); i++ ) {					\
			var _n = pt.value_to[| i];											\
			if(_n.value_from != pt) continue;									\
																				\
			if(variable_struct_exists(_n.node, "updateParticleForward"))		\
				_n.node.updateParticleForward();								\
		}																		\
	}
#endregion