$(document).ready(function() {
     $("#toggleGallerySwitch").click(function (e) {
        e.preventDefault();
        console.log("open / close gallery");
        $(".gallery-container").slideToggle('fast', function() {
                // Animation complete.
        });        
    });
    
     $("#insert-image").click(function (e) {
            e.preventDefault();            
            console.log("add image: " + $("#img-id").html() + " to Wiki Entry");
    });
    
    $("#gallery-selection" ).selectable({ 
        filter: "li", 
        selecting: function( event, ui ) {
            if( $(".ui-selected, .ui-selecting").length > 1){
                $(ui.selecting).removeClass("ui-selecting");
            }else {
                console.log("Selected! This: ", this, " Event:  ", event , " ui: ", ui);                                
                var atomTitle = "<span id='img-title-label' class='label'> Title: </span><span id='img-title'>"+$(ui.selecting).find('.atom-title').html();
                var atomId = "<span id='img-id-label' class='label'> Id: </span><span id='img-id'>"+$(ui.selecting).find('.atom-id').html()+"</span>";
                var uiContent = "<p>" + atomTitle + atomId + "</p>";
                $(".img-selected").html(uiContent);                    
            }
        },
        unselecting: function( event, ui ) {
           console.log("Unselected! This: ", this, " Event:  ", event , " ui: ", ui);                                
           $(".img-selected").html("");
        }
    });
    /* 
    $( ".gallery-draggable" ).draggable();
    $( "#gallery-droppable" ).droppable({
        drop: function( event, ui ) {            
            console.debug("this: ", this, " event: ",event, " ui:",ui);
        }
    });
    */
    
   $("#query-images").click(function (ev) {
       var searchForm = $(".form-search");
        ev.preventDefault();
        console.log("prepare query images");
        //  if (!form.checkValidity())
        //  return;
        contentEditor.deactivate();
        updateForm();
        // $("input[name='action']", form).val("store");
        var data = searchForm.serialize();
        console.debug("search data: ",data);
        $.ajax({
            type: "POST",
            url: "data/_theme/ImageSelector.html",
            data:data,
            complete: function() {
                $.log("updating gallery completed");
                contentEditor.activate();
            }
        }).done(function( html ) {
            // console.log("ajax.done html:",html)
            $("#imageSelector").replaceWith(html);
        });
    });
})


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