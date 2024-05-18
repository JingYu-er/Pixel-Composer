function Node_Websocket_Receiver(_x, _y, _group = noone) : Node(_x, _y, _group) constructor {
	name = "Websocket Receiver";
		
	inputs[| 0] = nodeValue("Port", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 22400);
	
	inputs[| 1] = nodeValue("Active", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
	
	inputs[| 2] = nodeValue("Mode", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 1)
		.setDisplay(VALUE_DISPLAY.enum_button, [ "Client", "Server" ]);
	
	inputs[| 3] = nodeValue("Url", self, JUNCTION_CONNECT.input, VALUE_TYPE.text, "");
	
	outputs[| 0] = nodeValue("Data", self, JUNCTION_CONNECT.output, VALUE_TYPE.struct, {});
	
	outputs[| 1] = nodeValue("Receive data", self, JUNCTION_CONNECT.output, VALUE_TYPE.trigger, false);
	
	input_display_list = [ 1, 2,
		["Connection", false], 0, 3,
	];
	
	connected_device = 0;
	network_trigger  = 0;
	port   = 0;
	mode   = 0;
	url    = "";
	socket = noone;
	client = noone;
	
	function setPort() { #region
		
		var _port = getInputData(0);
		var _mode = getInputData(2);
		var _url  = getInputData(3);
		
		if(_port == port && _mode == mode && _url == url) return;
		
		port = _port;
		mode = _mode;
		url	 = _url;
		
		if(ds_map_exists(PORT_MAP, port))
			array_remove(PORT_MAP[? port], self);
		
		if(!ds_map_exists(PORT_MAP, port))
			PORT_MAP[? port] = [];
		array_push(PORT_MAP[? port], self);
		
		if(socket != noone) 
			network_destroy(socket);
			
		if(mode == 0) {
			client = network_create_socket(network_socket_ws);
			network_connect_raw(client, url, port);
			
		} else if(mode == 1) {
			socket = network_create_server_raw(network_socket_ws, port, 16);
			if(socket)
				NETWORK_SERVERS[? newPort] = socket;
		}
	} #endregion
	
	setInspector(1, __txt("Refresh Server"), [ THEME.refresh_icon, 1, COLORS._main_value_positive ], function() { setPort(); });
	
	static asyncPackets = function(_async_load) { #region
		if(!active) return;
		
		var _active = getInputData(1);
		if(!_active) return;
		
		var type = async_load[? "type"];
		
		switch(type) {
			case network_type_connect :
				noti_status($"Websocket server: Client connected at port {port} on node {display_name}");
				connected_device++;
				break;
				
			case network_type_disconnect :
				noti_status($"Websocket server: Client disconnected at port {port} on node {display_name}");
				connected_device--;
				break;
				
			case network_type_data :
				var _buffer = async_load[? "buffer"];
				var _socket = async_load[? "id"];
				var data    = buffer_get_string(_buffer);
				
				var _data = json_try_parse(data, noone);
				if(_data == noone)	_data = { rawData: new Buffer(_buffer) }
				else				buffer_delete(_buffer);
					
				outputs[| 0].setValue(_data);
				network_trigger = true;
				break;
		}
	} #endregion
	
	static step = function() { #region
		var _mode = getInputData(2);
		
		inputs[| 3].setVisible(_mode == 0);
		
		if(network_trigger == 1) {
			outputs[| 1].setValue(1);
			network_trigger = -1;
		} else if(network_trigger == -1) {
			outputs[| 1].setValue(0);
			network_trigger = 0;
		}
	} #endregion
	
	static update = function(frame = CURRENT_FRAME) { #region
		if(CLONING) return;
		setPort();
	} #endregion
	
	static onDrawNode = function(xx, yy, _mx, _my, _s, _hover, _focus) { #region
		var _active = getInputData(1);
		var bbox    = drawGetBbox(xx, yy, _s);
		var network = ds_map_try_get(NETWORK_SERVERS, port, noone);
		
		var cc = CDEF.red, aa = 1;
		if(network >= 0) cc = CDEF.lime;
		if(!_active) aa = 0.5;
		
		var _y0 = bbox.y0 + ui(16);
		var _y1 = bbox.y1 - ui(16);
		var _ts = _s * 0.75;
		
		draw_set_text(f_code, fa_center, fa_top, COLORS._main_text);
		draw_set_alpha(0.75);
		draw_text_add(bbox.xc, bbox.y0, $"Port {port}", _ts);
		draw_set_valign(fa_bottom)
		draw_text_add(bbox.xc, bbox.y1, $"{connected_device} " + __txt("Connected"), _ts);
		draw_set_alpha(1);
		
		draw_sprite_fit(THEME.node_websocket_receive, 0, bbox.xc, (_y0 + _y1) / 2, bbox.w, _y1 - _y0, cc, aa);
	} #endregion
}