

function moveDown(itemid) {
  var item = $("#gallery-items #" + itemid),
    callback = function() {
      item.insertAfter(item.next());
    };
  item.fadeToggle(500, callback).fadeToggle(500);
}

function moveUp(itemid) {
  var item = $("#gallery-items #" + itemid),
    callback = function() {
       item.insertBefore(item.prev());
    };
  item.fadeToggle(500, callback).fadeToggle(500);
}

function remove(itemid) {
  var item = $("#gallery-items #" + itemid),
    callback = function() {
      item.remove();
    };
  item.fadeToggle(500, callback);
}