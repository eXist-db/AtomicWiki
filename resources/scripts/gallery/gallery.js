

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

function removeItem(itemid) {
    var gitem = $("#gallery-items #" + itemid);
    gitem.slideToggle(500, function() {
       gitem.remove();
    });
}

function showModal(itemid) {
    var dialog = $('#edit-gallery-item-dialog');
    var itemTitle = $('#' + itemid + " h3").text();
    var itemDesc = $('#' + itemid + " .image-desc").contents();
    
    dialog.find("input[name=title]").val(itemTitle);
    dialog.find("textarea[name=description]").append(itemDesc);
    
    dialog.modal('show');
}


function jumpTo(item){
    $('html,body').animate({scrollTop: item.offset().top},'slow');
}