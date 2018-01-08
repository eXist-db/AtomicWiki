To log into the wiki and change contents, an eXist-db user needs to be a member of the group `wiki.users`. Other users won't be able to log in - even if they have a valid database account.

Only the creator of a resource can change it's visibility to other users.

Read and write access to a resource can be restricted to:

* author/owner
* specific groups

Members of the special group `wiki-admin` can read/write any resource, ignoring any specific settings. By default the sole member of `wiki-admin` is the user `editor`.

# Changing Permissions

<figure class="wysiwyg-float-right">
    <img src="/help/permissions.png"/>
    <figcaption>Permissions Panel in Editor</figcaption>
</figure>

To change permissions, click on the "Permissions" link in either the feed settings popup or one of the editors. By default, a newly created feed or entry is *private*, i.e. only visible to the creator. Disabling the "private" checkbox reveals two other settings, which allow you to set:

1. read and write access for a specific group of users
2. make the resource readable for anyone, including users which are not logged in.

By default, only one group is defined: `users`. It includes *all authenticated wiki users*. Granting read/write access to group *users* essentially means that every valid user of the wiki should be able to see and/or modifiy the resource.

# Managing Groups and Users

<figure class="wysiwyg-float-right">
    <img src="/help/groupmanager.png"/>
    <figcaption>Group Manager Screen</figcaption>
</figure>

To manage groups and users in the wiki, you **must** be a member of the special group `wiki-admin` (*editor*) or an assigned **group manager** of one of the groups.

If above requirements are met, an entry *Manage Users* will be shown in the *Admin* dropdown menu. Clicking on it leads to the group editor, which can be used to

* create new groups
* add/remove users from groups
* create new users 

On a fresh install, only one group, `users`, with a member `editor` is available. To add another user, type its user name into the input box on the bottom right. If the user exists inside the database, it will be added to the currently selected group, otherwise a popup will ask you if you want to create a new user.

To create a new group, type its name into the input box on top of the table showing the current group's members and press the `+` button next to it. You may optionally also provide a description for the group.

After creating a new group, the group select should automatically switch to it and the table showing group members should become empty. You can now add new or existing users to the group.

All new or existing users added to a group automatically also become members of the global wiki group, `users`.

# Group Managers

A group manager is entitled to add or remove users to or from a specific group without being an admin user. To make a user a manager for a group, simply check the `Manager` check box.

Group managers cannot delete or create new groups.