function $(element) {
	if (typeof element == "string") {
		element=document.getElementById(element);
	}
	if (element)
		extend_instance(element,Element);
	return element;
}

function extend_instance(instance,hash) {
	for (var name in hash) {
		instance[name] = hash[name];
	}
}

var Element = {
	"hide": function () {
		this.setStyle("display","none")
	},
	"show": function () {
		this.setStyle("display","block")
	},
	"visible": function () {
		return (this.getStyle("display") != "none");
	},
	"toggle": function () {
		if (this.visible) {
			this.hide();
		} else {
			this.show();
		}
	}
};

function encodeURIComponent(str) {
	return str.replace('=','%3D').replace('&','%26');
};

var Form = {};
Form.serialize = function(form_element) {
	elements=$(form_element).serialize();
	param_string="";
	for (var name in elements) {
		if (param_string)	
			param_string += "&";
		param_string += encodeURIComponent(name)+"="+encodeURIComponent(elements[name]);
	}
	return param_string;
};

Ajax.Updater = function (container,url,options) {
  this.container = container;
	this.url=url;
	this.ajax = new Ajax();
	this.ajax.requireLogin = 1;
	if (options["onSuccess"]) {
		this.ajax.responseType = Ajax.JSON;
		this.ajax.ondone = options["onSuccess"];
	} else {
		this.ajax.responseType = Ajax.FBML;
		this.ajax.ondone = function(data) {
		  $(container).setInnerFBML(data);
		}
	}
	if (options["onFailure"]) {
		this.ajax.onerror = options["onFailure"];
	}
	// Yes, this is an excercise in undoing what we just did
	// FB doesn't provide encodeURI, but they will encode things passed as a hash
	// so we turn it into a string, esaping & and =
	// then we split it all back out here
	// this could be killed if encodeURIComponent was available
	parameters={};
	pairs=options['parameters'].split('&');
	for (var i=0; i<pairs.length; i++) {
		kv=pairs[i].split('=');
		key=kv[0].replace('%3D','=').replace('%26','&');
		val=kv[1].replace('%3D','=').replace('%26','&');
		parameters[key]=val;
	}
  this.ajax.post(url,parameters);	
};
Ajax.Request = function(url,options) {
	Ajax.Updater('unused',url,options);
};