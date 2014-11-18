var linkEditor;
var sitemap;
var anchorEditor;
var addGallery;
var addVideo;
var atomicEditor;
var form;
var isDirty = false;

$(document).ready(function() {
    form = $("#edit-form");

    linkEditor = new Atomic.editor.LinkToText();
    anchorEditor = new Atomic.editor.EditAnchor();
    addGallery = new Atomic.editor.AddGalleryLink();
    addVideo = new Atomic.editor.AddVideoLink();

// $(document).tooltip();
    $(".control-group").on("change","#title,#name", function(e) {
        e.preventDefault();
        console.log("title or name was changed");
        isDirty = true;
        return false;
    });

    $("body").on("click", "#dialog-cancel-action", function(e){
        console.log("close dialog");
        $("#unsaved-changes-dialog").modal('hide');        
    });

    $('body').on("click", "#dialog-save-action", function(e){
        console.log("persist unsaved changes");
        var feedURL = $("#dialog-form-url").val();        
        console.log("feed entry to open: ", feedURL);
        $("#unsaved-changes-dialog").modal('hide');
        saveGallery(feedURL);
    });


    $("#gallery").on("click", ".add-image", function(event){       
        event.preventDefault();
        addImage();
    }); 
    
    $("body").on("click", "#edit-form-save", function (e){                
        console.log("clicked #edit-form-save");
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
    $(".delete-button").click(function(ev) {
        //ev.preventDefault();
        console.log("clicked delete-button");
        var imageEntryId = $(".connected-atricle").attr("data-image-id");        
        console.log("remove referenced feed for image: ", imageEntryId);
        if(imageEntryId) {
            $(".connected-atricle").text("");
            $("#" + imageEntryId + "-content").text("");
            $("#" + imageEntryId + "-content").attr("data-description", ""); 
            $("#" + imageEntryId + "-content").attr("data-url", "");            
            $("#" + imageEntryId).find(".btn-pencil").attr('disabled', "disabled");                                        
        }
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
        loadImages(1)
    });
    
    $('.form-search').submit(function(e) {
        e.preventDefault;
        loadImages(1);
        return false;
    });
    
    // hide all admin-actions when in edit mode
    $(".actions .dropdown").hide();
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
        url: "ImageSelector.html",
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
    isDirty = true;
    var liTemplate = $("#li-template").clone()
    
    var imageTitle = $(".ui-selected .image-title").html();
    var imageURL = $(".ui-selected .image-url").html().replace("!150,150", "full");

    var imageId = Atomic.util.uuid();
    
    liTemplate.attr("id", imageId);    
    liTemplate.find(".thumb").attr("href",imageURL);
    liTemplate.find(".img-thumbnail").attr("alt",imageTitle);
    liTemplate.find(".img-thumbnail").attr("src",imageURL + "?width=256&amp;height=256&amp;crop_type=middle");
    
    liTemplate.find(".image-title").html(imageTitle); 
    liTemplate.find(".image-desc span").attr("id", imageId + "-content");
    liTemplate.find(".image-desc span").attr("data-description", "");
    liTemplate.find(".image-desc span").text("No description");



    liTemplate.find(".connect-edit").click(function() {
        // console.log("connect-pic clicked: imageId: ", imageId);
        openWikiArticle(imageId);
    });
    
    liTemplate.find(".connect-pic").click(function() {   
        console.log("connect-pic clicked: imageId: ", imageId);
        showSitemap(imageId);
       // showModal(imageId);
       // console.debug("show sitemap");
    });    
    
    liTemplate.find(".remove-pic").click(function() {   
       removeItem(imageId);
    });    
    liTemplate.find(".move-pic-up").click(function() {   
       moveUp(imageId);
    });    
    liTemplate.find(".move-pic-down").click(function() {   
       moveDown(imageId);
    });    
    
    // append the clonde and setup template into the gallery    
    liTemplate.appendTo("#gallery-items");
    
    jumpTo(liTemplate);
}

function moveDown(itemid) {
    isDirty = true;
    var item = $("#gallery-items #" + itemid);
    item.insertAfter(item.next());
    jumpTo(item);
}

function moveUp(itemid) {
    isDirty = true;
    var item = $("#gallery-items #" + itemid);
   item.insertBefore(item.prev());
    jumpTo(item);
}

function removeItem(itemid) {
    isDirty = true;
    var gitem = $("#gallery-items #" + itemid);
    var confirmed = confirm("Do you really want to delete this item?");
    if (confirmed) {
        gitem.slideToggle(500, function() {
           gitem.remove();
        });
    }
}

function showSitemap(imageEntryId) {
    console.log("opened sitemap: itemId: ", imageEntryId);
    var linkedArticleId = $("#" + imageEntryId + "-content").attr("data-description");
    console.log("linked Article: " + linkedArticleId);
    if(linkedArticleId){
        $(".connected-atricle").text($("#" + imageEntryId + "-content").text());
        $(".connected-atricle").attr("data-image-id", imageEntryId);
        $(".remove-linked-article").show();
        console.log("linked Article: " + linkedArticleId + " should be visible now!");
        
    }
    linkEditor.open(function(node) {
        console.log("selected: %o", node, " isDirty:", isDirty);
        if(node && node.data.key && node.data.title){
            $.ajax({
                type: "GET",
                url: "../modules/util.xql",
                data: { "action": "feedURL" , "title": node.data.title, "description": node.data.key },
                complete: function(data) {
                    console.log("complete: returned data: ",data);
                    //var readyState = data.readyState;
                    var responseText = jQuery.parseJSON(data.responseText);
                    // var status = data.status;
                    var statusText = data.statusText;
                    
                    if(statusText == "OK"){                                    
                        console.log("responseText url: ",responseText.wikiUrl);
                        $("#" + imageEntryId + "-content").text(node.data.title);
                        $("#" + imageEntryId + "-content").attr("data-description", node.data.key); 
                        $("#" + imageEntryId + "-content").attr("data-url", responseText.wikiUrl);
                                            
                        $("#" + imageEntryId).find(".btn-pencil").removeAttr('disabled');                                        
                        isDirty = true;                    
                    }                
                }
            });
        }
    });
  
}

function saveGallery(feedURL, feedId, imageEntryId) {
    $.log("save Gallery feedURL:",feedURL, " imageEntryId: ",imageEntryId, " feedId: ",feedId);
    isDirty = true;
    $("input[name='action']", form).val("store");
    $("input[name='ctype']", form).val("gallery");
    
    updateForm();
    var data = form.serialize() + "&unlock=false";
    $.ajax({
        type: "POST",
        url: "modules/store.xql",
        data: data,
        complete: function() {
            isDirty = false;
            if(feedURL){
                $.log("Store completed feedURL: ",feedURL, " imageEntryId: ",imageEntryId, " feedId: ",feedId);
                window.location = feedURL + "?action=edit";
            }else {
                $.log("Successfully saved Slideshow Feed");                
            }
        }
    });            
}

function openWikiArticle(imageId ) {
    if(!imageId || $("#" + imageId).find(".btn-pencil").attr('disabled')){
        return;
    }
    else {
        console.log("openWikiArticle for ImageId: ", imageId);
        var feedURL = $("#" + imageId + " .wiki-link span").attr("data-url");
        console.log("feedURL: ",feedURL);
        
        console.log("isDirty:", isDirty);
        if(isDirty === true){
            $("#unsaved-changes-dialog").modal('show');
            $("#dialog-form-url").val(feedURL);
        }
        else {
            window.location = feedURL + "?action=edit";
        }
    }
}


function updateForm() {
    var feedContent = $("#gallery-items").html();
    $("input[name='content']", form).val(feedContent);
    // console.dirxml(feedContent);        
}

function jumpTo(item){
    $('html,body').animate({scrollTop: item.offset().top},'slow');
}