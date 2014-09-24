Atomic.namespace("Atomic.users");

Atomic.users = (function () {
    
    var viewModel = null;
    
    function User() {
        this.id = ko.observable("");
        this.name = ko.observable();
        this.password1 = ko.observable();
        this.password2 = ko.observable();
        
        this.reset = function(id) {
            this.id(id);
            this.name("");
            this.password1("");
            this.password2("");
        };
        
        this.save = function(model) {
            var group = model.selectedGroup().name();
            var user = model.newUser;
            console.log("Creating user " + user.id());
            var data = {
                mode: "edit-user",
                id: user.id(),
                name: user.name(),
                password: user.password1(),
                group: group
            };
            $.ajax({
                url: "modules/users.xql",
                type: "POST",
                data: data,
                dataType: "json",
                success: function(data) {
                    if (data.status == "error") {
                        Atomic.util.Dialog.error("Saving User Failed", data.message, "fa-exclamation");
                    } else {
                        model.newUser.reset("");
                        Atomic.users.loadGroups(group);
                    }
                }
            });
        };
    }
    
    function loadGroups(selected) {
        $.ajax({
            url: "modules/users.xql?mode=groups",
            type: "GET",
            dataType: "json",
            timeout: 10000,
            success: function(data) {
                if (!viewModel) {
                    viewModel = ko.mapping.fromJS(data);
                    viewModel.selectedGroup = ko.observable();
                    viewModel.newGroup = {
                        name: ko.observable(),
                        description: ko.observable()
                    };
                    viewModel.addUser = ko.observable();
                    viewModel.newUser = new User();
                    ko.applyBindings(viewModel);
                } else {
                    ko.mapping.fromJS(data, viewModel);
                }
                if (selected) {
                    $.each(viewModel.group(), function(i, group) {
                        if (group.name() == selected) {
                            viewModel.selectedGroup(group);
                        }
                    });
                }
            }
        });
    }
    
    function createGroup(model) {
        var name = model.newGroup.name();
        var description = model.newGroup.description();
        $.ajax({
            url: "modules/users.xql",
            type: "GET",
            data: { mode: "create-group", id: name, description: description },
            dataType: "json",
            success: function(data) {
                if (data.status == "error") {
                    Atomic.util.Dialog.error("Group Creation Failed", data.message, "fa-exclamation");
                } else {
                    Atomic.users.loadGroups(name);
                    model.newGroup.name("");
                    model.newGroup.description("");
                }
            }
        });
    }
    
    function getLabel(item) {
        var name = item.name().replace(/^wiki\./, "");
        if (item.description()) {
            return name + ' (' + item.description() + ')';
        } else {
            return name;
        }
    }
    
    function addUser(model) {
        var group = model.selectedGroup().name();
        var user = model.addUser();
        if (user) {
            $.log("Adding user %s to group %s", model.addUser(), group);
            $.getJSON("modules/users.xql", { mode: "add-user", id: model.addUser(), group: group},
                function(data) {
                    if (data.status == "notfound") {
                        Atomic.util.Dialog.confirm("User Not Found", "User " + user + " does not exist. Create it?", function() {
                            model.newUser.reset(user);
                        });
                    } else {
                        Atomic.users.loadGroups(group);
                        model.addUser("");
                    }
                }
            );
        } else {
            Atomic.util.Dialog.error("Error", "No user specified!");
        }
    }
    
    function removeUser(item) {
        var group = viewModel.selectedGroup().name();
        $.log("Removing user %s from group %s", item.id(), group);
        $.getJSON("modules/users.xql", { mode: "remove-user", id: item.id(), group: group},
            function(data) {
                Atomic.users.loadGroups(group);
                model.addUser("");
            }
        );
    }
    
    return {
        loadGroups: loadGroups,
        createGroup: createGroup,
        getLabel: getLabel,
        addUser: addUser,
        removeUser: removeUser
    };
})();

$(document).ready(function() {
    var users = new Bloodhound({
        datumTokenizer: function(d) {
            return Bloodhound.tokenizers.whitespace(d.value);
        },
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        local: [],
        remote: 'modules/users.xql?mode=users&q=%QUERY'
    });
     
    users.initialize();
     
    $('.typeahead').typeahead(null, {
      name: 'users',
      displayKey: 'value',
      source: users.ttAdapter()
    });
    
    Atomic.users.loadGroups();
});