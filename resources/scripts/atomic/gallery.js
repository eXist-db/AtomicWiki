var linkEditor;
var sitemap;
var anchorEditor;
var addGallery;
var atomicEditor;
var form;

$(document).ready(function() {
    form = $("#edit-form");

    linkEditor = new Atomic.editor.LinkToText();
    anchorEditor = new Atomic.editor.EditAnchor();
    addGallery = new Atomic.editor.AddGalleryLink();

// $(document).tooltip();
    
    $("#gallery").on("click", ".add-image", function(event){        
        event.preventDefault();
        addImage();                
    }); 
    
    $("#edit-form-save").click(function (e){                
        e.preventDefault();
        saveGallery();    
    });
    
    $("#edit-form-saveAndClose").click(function(ev) {
        $("input[name='action']", form).val("store");
        $("input[name='ctype']", form).val("gallery");
        updateForm();
        form.submit();
        return false;
    });    
    
    $("#toggleGallerySwitch").click(function (e) {
        e.preventDefault();
        var gallery = $("#gallery");
        var  container = $(".gallery-container");
        gallery.toggleClass("galleryOpen");
        
    });
    loadImages();
    $("#query-images").click(function (ev) {   
        console.debug("clicke on load images button!")
       loadImages()
    });
    
    $('.form-search').submit(function(e) {
        e.preventDefault;
        loadImages();
        return false;
    });
    
});

function loadImages(start, max) {
    // console.debug("load images!")
    if(start) {
        // update hidden input name="start"
        $('#imagePickerStart').val(start);
    }
    if(max) {
        $('#imagePickerMax').val(max);
    }

    var searchForm = $(".form-search");
    console.log("prepare query images");

    var data = searchForm.serialize();
    console.debug("search data: ",data);
    
    // FIXME CHANGE THIS URL 
    // a relative url does not work here since we 
    // are creating collections for wiki sections
    $.ajax({
        type: "POST",
        url: "/exist/apps/wiki/data/_theme/ImageSelector.html",
        data:data,
        complete: function() {
            $.log("updating gallery completed");
            // contentEditor.activate();
        }
    }).done(function( html ) {
        // console.log("ajax.done html:",html)
        $("#imageSelector").replaceWith(html);
        $("#gallery-selection" ).selectable({ 
            filter: "li",
            tolerance: "fit" ,
            cancel: 'a',
            selecting: function( event, ui ) {
                console.debug("selecting event target " + event.target);
                if( $(".ui-selected, .ui-selecting").length > 1){
                    $(ui.selecting).removeClass("ui-selecting");
                }
                /* 
                else {
                    console.log("Selected! This: ", this, " Event:  ", event , " ui: ", ui);                                
                    var atomTitle = "<span id='img-title-label' class='label'> Title: </span><span id='img-title'>"+$(ui.selecting).find('.image-title').html()+"</span>";
                    var atomId = "<span id='img-id-label' class='label'> Id: </span><span id='img-id'>"+$(ui.selecting).find('.image-id').html()+"</span>";
                    var atomURL = "<span id='img-url-label' class='label'> URL: </span><span id='img-url'>"+$(ui.selecting).find('.image-url').html()+"</span>";
                    var uiContent = "<p>" + atomTitle + atomId + atomURL + "</p>";
                    $(".img-selected").html(uiContent);                                       
                }
                 */
            },
            
            unselecting: function( event, ui ) {
               // console.log("Unselected! This: ", this, " Event:  ", event , " ui: ", ui);                                
               // $(".img-selected").html("");
            }
        });
        $("#gallery").find("img" ).tooltip();
        /*
        $("#gallery").find("img" ).tooltip({
            position: {
                my: "center bottom+50",
                at: "center bottom"
            },
            open: function( event, ui ) {                
                ui.tooltip.animate({ top: ui.tooltip.position().bottom - 10 }, "fast" );
            }
        });
        */
        // $( "#gallery img" ).tooltip({ my: "right bottom+5", at: "right top" } );
        
    });
    
}

/*
 * Clones the template 'image' entry and populates it with data
*/
function addImage(){
    console.log("add image: " + $(".ui-selected .image-id").html() + " to Wiki Entry");
    var liTemplate = $("#li-template").clone()
    
    var imageTitle = $(".ui-selected .image-title").html();
    var imageURL = $(".ui-selected .image-url").html();
    
    var imageId = Atomic.util.uuid();
    
    liTemplate.attr("id", imageId);    
    liTemplate.find(".thumb").attr("href",imageURL);
    liTemplate.find(".img-polaroid").attr("alt",imageTitle);
    liTemplate.find(".img-polaroid").attr("src",imageURL); 
    
    liTemplate.find(".image-title").html(imageTitle); 
    liTemplate.find(".image-desc span").attr("id", imageId + "-content");
    liTemplate.find(".image-desc span").data("description", ""); 
    liTemplate.find(".image-desc span").text("No description"); 
    
    liTemplate.find(".btn-edit").click(function() {   
        console.log("btn-edit clicked: imageId: ", imageId);
        showSitemap(imageId);
       // showModal(imageId);
       // console.debug("show sitemap");
    });
    liTemplate.find(".btn-remove").click(function() {   
       removeItem(imageId);
    });    
    liTemplate.find(".btn-arrow-up").click(function() {   
       moveUp(imageId);
    });    
    liTemplate.find(".btn-arrow-down").click(function() {   
       moveDown(imageId);
    });    
    
    // append the clonde and setup template into the gallery    
    liTemplate.appendTo("#gallery-items")
    
    jumpTo(liTemplate);
}

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

function showSitemap(imageEntryId, feedId) {
    console.log("opened sitemap: itemId: ", imageEntryId, " feed: ",feedId);
    linkEditor.open(function(node) {
        console.log("selected: %o", node);
        $("#" + imageEntryId + "-content").text(node.data.title);
        $("#" + imageEntryId + "-content").attr("data-description", node.data.key);
    });
    /* linkEditor.open(imageEntryId, function() {
        console.debug("open xyz: itemId: ",imageEntryId);
    });*/
    // linkEditor.onSelect = function(data){
    //     console.debug("selected item arguments: url:", data.url, " align: ", data.align);          
    //     saveGallery(data.url, feedId, imageEntryId);        
    // };

}

function saveGallery(feedURL, feedId, imageEntryId) {
    $.log("save Gallery feedURL:",feedURL, " imageEntryId: ",imageEntryId, " feedId: ",feedId);
    $("input[name='action']", form).val("store");
    $("input[name='ctype']", form).val("gallery");
    
    updateForm();
    var data = form.serialize() + "&unlock=false";
    $.ajax({
        type: "POST",
        url: "modules/store.xql",
        data: data,
        complete: function() {
            $.log("Store completed feedURL: ",feedURL, " imageEntryId: ",imageEntryId, " feedId: ",feedId);
            window.location = feedURL + "?action=edit&image="+imageEntryId+"&feed=" + feedId;
        }
    });            

}
function updateForm() {
    var feedContent = $("#gallery-items").html();
    $("input[name='content']", form).val(feedContent);
    // console.dirxml(feedContent);        
}

function jumpTo(item){
    $('html,body').animate({scrollTop: item.offset().top},'slow');
}