

function moveDown(itemid) {
    var item = $("#gallery-items #" + itemid),
        callback = function() {
            item.insertAfter(item.next());
        };
    item.toggle(250, callback).toggle(250);
    jumpTo(item.next());
}

function moveUp(itemid) {
    var item = $("#gallery-items #" + itemid),
        callback = function() {
           item.insertBefore(item.prev());
        };
    item.toggle(250, callback).toggle(250);
    jumpTo(item.prev());
}

function remove(itemid) {
    var item = $("#gallery-items #" + itemid),
        callback = function() {
           item.remove();
        };
    item.slideToggle(500, callback);
}

function jumpTo(item){
    $('html,body').animate({scrollTop: item.offset().top},'slow');
}