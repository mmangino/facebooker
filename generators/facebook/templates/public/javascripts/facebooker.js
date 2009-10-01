function $(element) {
    if (typeof element == "string") {
        element=document.getElementById(element);
    }
    if (element)
        extendInstance(element,Element);
    return element;
}

function getElementsByName(elementName) {        
    var matcher = function(element) {
        return (element.getName() === elementName);				
    };			        
    return domCollect(document.getRootElement(), matcher);
}
function getElementsByClass(classname) {    
    var matcher = function(element) {
        return (element.getClassName() === classname);
    };
    return domCollect(document.getRootElement(), matcher);
}
//function getElementsByTagName(tagName) -> native to FJBS

extendInstance(Ajax, { //Extends the native Facebook Ajax object
    /*
     * Make a request to a remote server. Call the 'success' callback with the result.
     * Ex: 	Ajax.Load('JSON','http://...',{ success: function(result){console.log(result.toSource())} }, {'json':test_content})
     */
    Load: function(response_type, action_path, callbacks, post_parameters) {
        callbacks = Ajax.checkCallbacks(callbacks);		
        var ajax = new Ajax();
        switch(response_type) {
            case 'FBML':
                ajax.responseType = Ajax.FBML;
                break;
            case 'JSON':
                ajax.responseType = Ajax.JSON;
                break;
            case 'RAW':
                ajax.responseType = Ajax.RAW;
                break;
            default:
                console.error("Unknow respons format requested. You supplied %s. Supported: 'FBML', 'RAW'", response_type);
                return;										
        }
        ajax.ondone = function(result){
            callbacks.success(result);
            callbacks.complete();
        }
        ajax.onerror = function(error_string) {
            callbacks.failure(error_string);
            callbacks.complete();
        }
        
        post_parameters = post_parameters || {}
        post_parameters['authenticity_token'] = _token;

        if(action_path.indexOf('http') == -1) {
            action_path = _hostname + action_path;			
        }                      

        callbacks.begin();
        ajax.post(action_path,post_parameters);
    },
    /*
     * Make a request to a remote server. Update target_element with result. Calls the 'success' callback with the result
     * Ex: Ajax.Update('test1', 'FBML', 'http://...',{ success: function(result){console.log(result)} })
     */
    Update: function(target_element, response_type, action_path, callbacks, post_parameters) {
        callbacks = Ajax.checkCallbacks(callbacks);        
        var update_element = function(content) {
            switch(response_type) {
                case 'FBML':
                    $(target_element).setInnerFBML(content);
                    break;
                case 'RAW':
                    $(target_element).setTextValue(content);					
                    break;
                default:
                    console.log("Unsupported response type "+response_type);
                    break;
            }
        };

        var onsuccess = (callbacks.success == null)?
        update_element :
        chainMethods([update_element,callbacks.success]);

        callbacks.success = onsuccess;        
        Ajax.Load(response_type, action_path, callbacks, post_parameters);
    },


    InPlaceInputEditor: function(target_element, action_path, post_parameters) {
        var classname = $(target_element).getClassName() || "";

        this.edit = function() {
            var target = $(target_element);	
            var wrapper = target.getParentNode();			
            var dimensions = $(target_element).getDimensions();	
            var value = $(target_element+'__value').getValue();

            var editArea = document.createElement('input');
            editArea.setType($(target_element+'__value').getType());
            editArea.setId(target_element+"__editor");
            editArea.setValue(value);
            //editArea.focus();
            //editArea.setStyle("width",dimensions.width+"px");
            //editArea.setStyle("height", dimensions.height+'px');

            $(target_element+'__value').remove();
            wrapper.removeChild(target);
            wrapper.appendChild(editArea);
        }
        this.save = function(callbacks){
            var newValue = $(target_element + "__editor").getValue();
            var wrapper = $(target_element + "__editor").getParentNode();
            callbacks = Ajax.checkCallbacks(callbacks);
            Ajax.Load("RAW", action_path + "?raw=" + escape(newValue), {
                success: chainMethods([
                    callbacks.success,						
                    function(result){
                        wrapper.setInnerXHTML('<span>'+
                            '<input id="'+target_element+'__value" name="'+target_element+'__value" style="display:none;" type="text" value="'+unescape(result)+'" />'+
                            '<span><span id="'+target_element+'" class="'+classname+'" type="text">'+unescape(result)+'</span></span></span>');
                    }
                    ])
            }, post_parameters)
        };
    },
    InPlaceTextAreaEditor: function(target_element, action_path, post_parameters) {
        var classname = $(target_element).getClassName() || "";
				
        this.edit = function() {
            var target = $(target_element);	
            var wrapper = target.getParentNode();			
            var dimensions = $(target_element).getDimensions();	
            var value = $(target_element+'__value').getValue();

            var editArea = document.createElement('textarea');
            editArea.setId(target_element+"__editor");
            editArea.setValue(value.replace(/<br \/>|<br\/>/g,'\n').replace(/<p>|<\/p>/g,''));
            editArea.addEventListener('keyup', function() {
                autoExpandTextarea(editArea);
            });
            //editArea.focus();
            editArea.setStyle("width",dimensions.width+"px");
            //editArea.setStyle("height", dimensions.height+'px');

            $(target_element+'__value').remove();
            wrapper.removeChild(target);
            wrapper.appendChild(editArea);
            autoExpandTextarea(editArea);
        }
        this.save = function(callbacks){
            var newValue = $(target_element + "__editor").getValue();
            var wrapper = $(target_element + "__editor").getParentNode();
            callbacks = Ajax.checkCallbacks(callbacks);
            Ajax.Load("RAW", action_path + "?raw=" + escape(newValue), {
                success: chainMethods([
                    callbacks.success,						
                    function(result){
                        wrapper.setInnerXHTML('<span>'+
                            '<textarea id="'+target_element+'__value" name="'+target_element+'__value" style="display:none;">'+unescape(result.replace(/<br \/>|<br\/>/g,'\n').replace(/<p>|<\/p>/g,''))+'</textarea>'+
                            '<div><div id="'+target_element+'" class="'+classname+'" type="text">'+unescape(result)+'</div></div></span>');
                    }
                    ])
            }, post_parameters)
        };
    },
    /*
     * Pass the data inside of a form to a target url and place the result inside target_element. 
     * Calls the 'success' callback with the result
     */
    UpdateRemoteForm: function(form_element, target_element, response_type, target_action, callbacks) {
        callbacks = callbacks || {};
        Ajax.Update(target_element, response_type, target_action, callbacks, $(form_element).serialize());
    },	
    checkCallbacks:function(callbacks) {
        callbacks = callbacks || {};		
        var donothing = function(){};
        return callbacks = {
            success: callbacks.success 		|| donothing,
            failure: callbacks.failure		|| donothing,
            begin: callbacks.begin 		|| donothing,
            complete: callbacks.complete 	|| donothing	
        };
    }
});

/*
 * Displays a confirmation dialog. If the user clicks "continue" then callback will be evaluated.
 * title and message can be strings or fb:js-string objects
 */
function confirm(title,message,callback) {
    dialog = new Dialog(Dialog.DIALOG_POP);

    dialog.showChoice(
        title,
        message, // Content
        'Continue',
        'Cancel');

    dialog.onconfirm = function() {
        callback();
    };
}

function chainMethods(callbacks) {
    return function(par1,par2,par3,par4,par5,par6) {
        for (var i = 0, l = callbacks.length; i < l; i++) {
            callbacks[i](par1, par2, par3, par4, par5, par6);
        }
    }
}

function extendInstance(instance,hash) {
    for (var name in hash) {
        instance[name] = hash[name];
    }
}

var Element = {
    visible: function() {
        return (this.getStyle('display') != 'none');
    },
    toggle: function() {
        if (this.visible()) {
            this.hide();
        } else {		
            this.show();
        }
    },
    hide: function() {
        this.setStyle({
            display:'none'
        });
        return this;
    },
    show: function(element) {
        this.setStyle({
            display:''
        });
        return this;	
    },
    remove: function() {
        this.getParentNode().removeChild(this);
        return null;
    },
    /*
     * Returns calculated element size
     */
    getDimensions: function() {
        var display = this.getStyle('display');
        if (display != 'none' && display != null) // Safari bug
            return {
                width: this.getOffsetWidth(),
                height: this.getOffsetHeight()
                };

        // All *Width and *Height properties give 0 on elements with display none,
        // so enable the element temporarily
        var originalVisibility = this.getStyle("visibility");
        var originalDisplay = this.getStyle("display");
        var originalPosition = this.getStyle("position");
        this.setStyle('visibility','none');
        this.setStyle('display','block');
        this.setStyle('position','absolute');
        var originalWidth = this.getClientWidth();
        var originalHeight = this.getClientHeight();
        this.setStyle('visibility',originalVisibility);
        this.setStyle('display',originalDisplay);
        this.setStyle('position',originalPosition);

        return {
            width: originalWidth,
            height: originalHeight
        };
    }
}

function encodeURIComponent(str) {
    if (typeof(str) == "string") {
        return str.replace(/=/g,'%3D').replace(/&/g,'%26');
    }
    //checkboxes and radio buttons return objects instead of a string
    else if(typeof(str) == "object"){
        for (prop in str)
        {
            return str[prop].replace(/=/g,'%3D').replace(/&/g,'%26');
        }
    }
    return "";
}

/*
 * Applies block to all elements of an array. Return the array itself.
 */
function map(array, block){ 
    results = [];
    for (var i=0,l=array.length;i<l;i++){ 
        results.push(block(array[i]));
    }
    return results;
}

/*
 * Collects all elements within the 'element' tree that 'matcher' returns true for
 * For an example, see selectElementsByClass
 */
function domCollect(element, matcher) {
    collection = [];
    var recurse = function(subelement){		
        var nodes = subelement.getChildNodes();
        map(nodes, function(node){
            if (matcher(node)) {                
                extendInstance(node,Element)
                collection.push(node);
            }
            if (node.getFirstChild()) {
                recurse(node);
            }
        });
    };
    recurse(element);
    return collection;
}

PeriodicalExecuter = function (callback, frequency) {
        setTimeout(callback, frequency *1000);
        setTimeout(function() { new PeriodicalExecuter(callback,frequency); }, frequency*1000);
};