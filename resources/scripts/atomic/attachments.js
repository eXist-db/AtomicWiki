Atomic.namespace("Atomic.editor.Attachments");

Atomic.editor.Attachments = (function () {
    
    var dialog;
    var body;
    var collection;
    
    $(document).ready(function() {
        var collection = $("#edit-form input[name=collection]").val();
        var container = $("#image-upload");
        $.log("Initializing uploads: %o", container);
        var pending = 0;
        var progressDiv = $(".overall-progress", container);
        var errorsFound = false;
        $(container).find("input[name=collection]").val(collection);
        $(container).fileupload({
            sequentialUploads: true,
            dataType: "json",
            add: function(e, data) {
                var rows = "";
                for (var i = 0; i < data.files.length; i++) {
                    rows += "<tr>";
                    rows += "<td class='name'>" + data.files[i].name + "</td>";
                    rows +="<td>" + Math.ceil(data.files[i].size / 1024) + "k</td>";
                    rows += "<td class='progress'><div class='bar' style='width: 0'></div></td>";
                    rows += "</tr>";
                }
                data.context = $(".files", container).append(rows);
                pending += 1;
                data.submit();
            },
            progress: function (e, data) {
                var progress = parseInt(data.loaded / data.total * 100, 10);
                $('.bar', data.context).css("width", progress + "%");
            },
            progressall: function (e, data) {
                var progress = parseInt(data.loaded / data.total * 100, 10);
                if (!progressDiv.is(":visible")) {
                    progressDiv.show();
                }
                if (progress == 100 && progressDiv.is(":visible")) {
                    progressDiv.hide();
                    progress = 0;
                }
                $(".overall-progress .bar", container).css("width", progress + "%");
                $(".overall-progress .progress-label", container).html(progress + "%");
            },
            done: function(e, data) {
                pending -= 1;
                if (data.result[0].error) {
                    $(".progress", data.context).html(data.result[0].error);
                    errorsFound = true;
                } else {
                    var result = data.result[0];
                    var tr = "<tr><td>" + result.file + "</td>";
                    if (result.thumbnail) {
                        tr += "<td><img src='modules/images.xql?size=64&image=" + result.thumbnail + "'></td>";
                    } else {
                        tr += "<td></td>";
                    }
                    tr += "<td>" + result.type + "</td></tr>";
                    $("#attachments .attachments").append(tr);
                    $(data.context).remove();
                }
                if (pending < 1) {
                    progressDiv.hide();
                    progress = 0;
                }
            },
            fail: function(e, data) {
                $(".progress", data.context).html(data.jqXHR.statusText);
            }
        });
    });
}());