$(document).ready(function() {
    
    var form = $("#edit-form");
    var sitemap = new Atomic.editor.EditLink();
    var addImage = new Atomic.editor.ImageLink();
    var anchorEditor = new Atomic.editor.EditAnchor();
    var addGallery = new Atomic.editor.AddGalleryLink();
    var addVideo = new Atomic.editor.AddVideoLink();
    var addMusic = new Atomic.editor.AddMusicLink();
    var summaryEditor = null;
    
    $(window).on("unload", function() {
        var collection = $("#edit-form input[name='collection']").val();
        var resource = $("#edit-form input[name='resource']").val();
        $.ajax({
            type: "GET",
            url: "modules/store.xql",
            data: {
                action: "unlock",
                collection: collection,
                resource: resource
            },
            async: false
        });
    });
    
    var contentEditor = null;
    contentEditor = new Atomic.editor.Editor("content-editor-content", "content-editor-textarea", "content-editor-toolbar", sitemap, addImage, anchorEditor, addGallery, addVideo, addMusic);
    $("#content-editor-content").remove();
        
    function updateForm() {
        var content = null;
        content = contentEditor.editor.getValue(true);
        
        var summary = null;
        if (summaryEditor) {
            summary = summaryEditor.editor.getValue(true);
        }
        
        var name = $("input[name='name']", form).val();
        form.attr("action", name);
        $("textarea[name='content']", form).val(content);
        if (summary) {
            $("textarea[name='summary']", form).val(summary);
        }
    }
    
    function generateGroupPermissionsDescriptor() {
        var groupPermissionsContainer = $("table.permissions");
        var groupPermissionsDescriptor = "";
        $("tr.perm-detail:not(:last)", groupPermissionsContainer).each(function(index) {
            var $this = $(this);
            var groupName = $("select[name = 'perm-group']", $this).val();
            var read = $("input.perm-group-read", $this).is(":checked") ? "r" : "-";
            var write = $("input.perm-group-write", $this).is(":checked") ? "w" : "-";
            var groupPermissionDescriptor = read + write;
            if (groupName !== "" && groupPermissionDescriptor !== "") {
                var permission = groupName + " " + groupPermissionDescriptor;
                groupPermissionsDescriptor += permission + ",";
            }
        });
        groupPermissionsDescriptor = groupPermissionsDescriptor.replace(/,$/, "");
        
        return groupPermissionsDescriptor;
    }
    
    
    $("#summary-editor-tab").click(function (e) {
        e.preventDefault();
        if (!summaryEditor) {
            summaryEditor = new Atomic.editor.Editor("summary-editor-content", "summary-editor-textarea", "summary-editor-toolbar", sitemap, addImage, anchorEditor, addGallery, addVideo, addMusic);
            $("#summary-editor-content").remove();
        }
        $(this).tab('show');
    });
    $("#content-editor-tab").click(function (e) {
        e.preventDefault();
        $(this).tab('show');
    });

    $("#edit-form-saveAndClose").click(function(ev) {
//        if (!form.checkValidity()) {
//            return;
//        }
        if (contentEditor) {
            contentEditor.deactivate();
        }
        updateForm();
        var groupPermissions = generateGroupPermissionsDescriptor();
        $("input[name='action']", form).val("store");
        $("input[name='groupPermissions']", form).val(groupPermissions);
        form.submit();
        return false;
    });
    
    $("#edit-form-save").click(function (ev) {
        ev.preventDefault();
        
//        if (!form.checkValidity())
//            return;
        if (contentEditor) {
            contentEditor.deactivate();
        }
        updateForm();
        var groupPermissions = generateGroupPermissionsDescriptor();
        $("input[name='action']", form).val("store");
        $("input[name='groupPermissions']", form).val(groupPermissions);
        var data = form.serialize() + "&unlock=false";
        $.ajax({
            type: "POST",
            url: "modules/store.xql",
            data: data,
            complete: function() {
                $.log("Store completed");
                if (contentEditor) {
                    contentEditor.activate();
                }
            }
        });
    });
    $("#edit-form-cancel").click(function(ev) {
        $("input[name='action']", form).val("unlock");
        form.submit();
        return true;
    });
    
    Atomic.Form.validator(form, ["name"]);
    
    form.submit(function () {
        if ($("input[name='action']", form).val() == "unlock") {
            return true;
        }
        var wikiId = $("input[name='name']", this).val();
        var filename = $("input[name='resource']", this).val();
        
        if (wikiId === "") {
            return false;
        }
        if (filename === "") {
            filename = wikiId + ".atom";
            $("input[name='resource']", this).val(filename);
        }
        
        return true;
    });
    
    $(".actions .dropdown").hide();
});