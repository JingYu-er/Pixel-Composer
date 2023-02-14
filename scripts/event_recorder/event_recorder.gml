globalvar UNDO_STACK, REDO_STACK;
globalvar IS_UNDOING, UNDO_HOLDING;
	
IS_UNDOING		= false;
UNDO_HOLDING	= false;
UNDO_STACK		= ds_stack_create();
REDO_STACK		= ds_stack_create();

enum ACTION_TYPE {
	var_modify,
	list_modify,
	list_insert,
	list_delete,
	
	node_added,
	node_delete,
	junction_connect,
	junction_disconnect,
	
	group_added,
	group_removed,
	
	group,
	ungroup,
	
	collection_loaded,
}

enum DS_TYPE {
	array,
	list,
}

function Action(_type, _object, _data) constructor {
	type = _type;
	obj  = _object;
	data = _data;
	extra_data = 0;
	
	static undo = function() {
		var _n;
		
		switch(type) {
			case ACTION_TYPE.var_modify : 
				if(is_struct(obj)) {
					_n = variable_struct_get(obj, data[1]);
					variable_struct_set(obj, data[1], data[0]);
				} else if(object_exists(obj)) {
					_n = variable_instance_get(obj, data[1]);
					variable_instance_set(obj, data[1], data[0]);
				}
				data[0] = _n;
				break;
			case ACTION_TYPE.list_insert :
				if(!ds_exists(obj, ds_type_list)) return;
				ds_list_delete(obj, data[1]);
				PANEL_ANIMATION.updatePropertyList();
				break;
			case ACTION_TYPE.list_modify :
				if(!ds_exists(obj, ds_type_list)) return;
				_n = data[0];
				obj[| data[1]] = data[0];
				data[0] = _n;
				break;
			case ACTION_TYPE.list_delete :
				if(!ds_exists(obj, ds_type_list)) return;
				ds_list_insert(obj, data[1], data[0]);
				break;
			case ACTION_TYPE.node_added :
				nodeDelete(obj);
				break;
			case ACTION_TYPE.node_delete :
				obj.restore();
				break;
			case ACTION_TYPE.junction_connect :
				var _d = obj.value_from;
				obj.setFrom(data);
				data = _d;
				break;
			case ACTION_TYPE.junction_disconnect :
				obj.setFrom(data);
				break;
			case ACTION_TYPE.group_added :
				obj.remove(data);
				break;
			case ACTION_TYPE.group_removed :
				obj.add(data);
				break;
			case ACTION_TYPE.group :
				upgroupNode(obj, false);
				break;
			case ACTION_TYPE.ungroup :
				obj.restore();
				groupNodes(data.content, obj, false);
				break;
			case ACTION_TYPE.collection_loaded :
				for( var i = 0; i < array_length(obj); i++ ) 
					nodeDelete(obj[i]);
				break;
		}
	}
	
	static redo = function() {
		var _n;
		switch(type) {
			case ACTION_TYPE.var_modify :
				if(is_struct(obj)) {
					_n = variable_struct_get(obj, data[1]);
					variable_struct_set(obj, data[1], data[0]);
				} else if(object_exists(obj)) {
					_n = variable_instance_get(obj, data[1]);
					variable_instance_set(obj, data[1], data[0]);	
				}
				data[0] = _n;
				break;
			case ACTION_TYPE.list_insert :
				if(!ds_exists(obj, ds_type_list)) return;
				ds_list_insert(obj, data[1], data[0]);
				PANEL_ANIMATION.updatePropertyList();
				break;
			case ACTION_TYPE.list_modify :
				if(!ds_exists(obj, ds_type_list)) return;
				_n = data[0];
				obj[| data[1]] = data[0];
				data[0] = _n;
				break;
			case ACTION_TYPE.list_delete :
				if(!ds_exists(obj, ds_type_list)) return;
				ds_list_delete(obj, data[1]);
				break;
			case ACTION_TYPE.node_added :
				obj.restore();
				break;
			case ACTION_TYPE.node_delete :
				nodeDelete(obj);
				break;
			case ACTION_TYPE.junction_connect :
				var _d = obj.value_from;
				obj.setFrom(data);
				data = _d;
				break;
			case ACTION_TYPE.junction_disconnect :
				obj.removeFrom();
				break;
			case ACTION_TYPE.group_added :	
				obj.add(data);
				break;
			case ACTION_TYPE.group_removed :
				obj.remove(data);
				break;
			case ACTION_TYPE.group :
				obj.restore();
				groupNodes(data.content, obj, false);
				break;
			case ACTION_TYPE.ungroup :
				upgroupNode(obj, false);
				break;
			case ACTION_TYPE.collection_loaded :
				for( var i = 0; i < array_length(obj); i++ )
					obj[i].restore();
				break;
		}
	}
	
	static toString = function() {
		var ss = "";
		switch(type) {
			case ACTION_TYPE.var_modify :
				if(array_length(data) > 2)
					ss = "modify " + string(data[2]);
				else 
					ss = "modify " + string(data[1]);
				break;
			case ACTION_TYPE.list_insert :
				if(array_length(data) > 2)
					ss = data[2];
				else 
					ss = "insert " + string(data[1]) + " to list " + string(obj);
				break;
			case ACTION_TYPE.list_modify :
				ss = "modify " + string(data[1]) + " of list " + string(obj);
				break;
			case ACTION_TYPE.list_delete :
				ss = "delete " + string(data[1]) + " from list " + string(obj);
				break;
			case ACTION_TYPE.node_added :
				ss = "add " + string(obj.name) + " node";
				break;
			case ACTION_TYPE.node_delete :
				ss = "deleted " + string(obj.name) + " node";
				break;
			case ACTION_TYPE.junction_connect :
				ss = "connect " + string(obj.name);
				break;
			case ACTION_TYPE.junction_disconnect :
				ss = "disconnect " + string(obj.name);
				break;
			case ACTION_TYPE.group_added :
				ss = "add " + string(obj.name) + " to group";
				break;
			case ACTION_TYPE.group_removed :
				ss = "remove " + string(obj.name) + " from group";
				break;
			case ACTION_TYPE.group :
				ss = "group " + string(array_length(data.content)) + " nodes";
				break;
			case ACTION_TYPE.ungroup :
				ss = "ungroup " + string(obj.name) + " node";
				break;
			case ACTION_TYPE.collection_loaded :
				ss = "load " + string(filename_name(data));
				break;
		}
		return ss;
	}
}

function recordAction(_type, _object, _data = -1) { 
	if(IS_UNDOING)		return;
	if(LOADING)			return;
	if(UNDO_HOLDING)	return;
	
	var act = new Action(_type, _object, _data);
	array_push(o_main.action_last_frame, act);
	ds_stack_clear(REDO_STACK);
	
	return act;
}

function UNDO() {
	if(ds_stack_empty(UNDO_STACK))				return;
	if(instance_exists(_p_dialog_undo_block))	return;
	
	IS_UNDOING = true;
	var actions = ds_stack_pop(UNDO_STACK);
	for(var i = array_length(actions) - 1; i >= 0; i--)
		actions[i].undo();
	IS_UNDOING = false;
	Render();
	
	ds_stack_push(REDO_STACK, actions);
}

function REDO() {
	if(ds_stack_empty(REDO_STACK))				return;
	if(instance_exists(_p_dialog_undo_block))	return;
	
	IS_UNDOING = true;
	var actions = ds_stack_pop(REDO_STACK);
	for(var i = 0; i < array_length(actions); i++)
		actions[i].redo();
	IS_UNDOING = false;
	Render();
	
	ds_stack_push(UNDO_STACK, actions);	
}