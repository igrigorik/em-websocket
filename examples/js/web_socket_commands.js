
var allowed_commands = ['alert', 'javascript', 'prompt'];

$(document).ready(function(){
  function debug(str){ $("#debug").append("<p>"+str+"</p>"); };

  ws = new WebSocket("ws://localhost:8080");
  ws.onmessage = function(evt) { 
    socket_command(evt.data);
    $("#msg").append("<p>"+evt.data+"</p>"); 
  };
  ws.onclose = function() { debug("socket closed"); };
  ws.onopen = function() {
    debug("connected...");
    ws.send("hello server");
  };
});

function socket_command(msg){
  try{
    jsonmsg = JSON.parse(msg);
    vars = jsonmsg.vars;
    command = jsonmsg.method_name;
  }catch(err){
    command = "";
    vars = [];
  }
  if(allowed_commands.contains(command)){
    //javascript is a special command where the rest of the arguments are just evaluated.
    if(command=='javascript'){
      for(x in vars){
        eval(vars[x].value);
      }
    }else{
      vars_array = [];
      for(x in vars){
        //right now we only have String and not NotString
        switch(vars[x].type){
          case 'String':
            vars_array.push("'"+vars[x].value+"'");
            break;
          default:
            vars_array.push(""+vars[x].value+"");
        }
      }
      eval(command+"("+vars_array.join(",")+")");
    }
  }else{
    $("#debug").append("<p>"+msg+"</p>");
  }
}
Array.prototype.contains = function(obj) {
  var i = this.length;
  while (i--) {
    if (this[i] === obj) {
      return true;
    }
  }
  return false;
}