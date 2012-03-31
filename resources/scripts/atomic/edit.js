Aloha.ready( function() {
    
    var form = $("#edit-form");
    
    function updateForm() {
        var content = Aloha.getEditableById("content-editor-html").getContents(false);
        var summary = Aloha.getEditableById("summary-editor-html").getContents(false);
        $("textarea[name='content']", form).val(content);
        $("textarea[name='summary']", form).val(summary);
    }
    
    Aloha.jQuery('#content-editor-html').aloha();
    Aloha.jQuery('#summary-editor-html').aloha();
    
    $("#editor-switch").click(function(ev) {
        ev.preventDefault();
        var name = $("input[name='name']").val();
        var title = $("input[name='title']").val();
        if (name === "" && title === "") {
            Atomic.util.Dialog.confirm("Switch to Wiki markup editor",
                "The page will be <strong>reloaded</strong>! Please note that " +
                "the HTML editor is not as extensible as the wiki editor and some formatting " + 
                "<strong>might get lost</strong> when switching back at a later point.", 
                function () {
                    window.location = "?action=addentry&editor=wiki";
                }
            );
        } else {
            Atomic.util.Dialog.confirm("Switch to Wiki markup editor",
                "The form needs to be saved before switching editors. Please note that " +
                "the HTML editor is not as extensible as the wiki editor!", 
                function () {
                    $("input[name='editor']", form).val("wiki");
                    $("input[name='action']", form).val("switch-editor");
                    form.submit();
                }
            );
        }
    });
    
    $("#edit-form-saveAndClose").click(function(ev) {
        $("input[name='action']", form).val("store");
        return true;
    });
    $("#edit-form-save").click(function (ev) {
        ev.preventDefault();
        
        updateForm();
        var data = form.serialize();
        $.ajax({
		    type: "POST",
		    url: "modules/store.xql",
		    data: data
        });
    });
    
    Atomic.Form.validator(form, ["name"]);
    
    form.submit(function () {
        var wikiId = $("input[name='name']", this).val();
        var filename = $("input[name='resource']", this).val();
        
        if (wikiId === "") {
            return false;
        }
        if (filename === "") {
            filename = wikiId + ".atom";
            $("input[name='resource']", this).val(filename);
        }
        
        updateForm();
        return true;
    });
});