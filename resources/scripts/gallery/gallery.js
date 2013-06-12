

function moveDown(itemid) {
    var item = $("#gallery-items #" + itemid);
    item.insertAfter(item.next());
    jumpTo(item);
}

function moveUp(itemid) {
    var item = $("#gallery-items #" + itemid);
   item.insertBefore(item.prev());
    jumpTo(item);
}

function removeItem(itemid) {
    var gitem = $("#gallery-items #" + itemid);
    var confirmed = confirm("Do you really want to delete this item?");
    if (confirmed) {
        gitem.slideToggle(500, function() {
           gitem.remove();
        });
    }
}

function showModal(itemid) {
    var dialog = $('#edit-gallery-item-dialog');
    var itemTitle = $('#' + itemid + " h3").text();
    var itemDesc = $('#' + itemid + "-desc").children();
    
    dialog.find("input[name=title]").val(itemTitle);
    
    var anchorEditor = new Atomic.editor.EditAnchor();
    var editor = new Atomic.editor.Editor(itemid + "-desc", "description", "editor-toolbar", sitemap, anchorEditor);
    
    dialog.modal('show');
}


function jumpTo(item){
    $('html,body').animate({scrollTop: item.offset().top},'slow');
}