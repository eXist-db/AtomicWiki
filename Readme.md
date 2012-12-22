AtomicWiki
==========

AtomicWiki is a wiki engine, tightly integrated with the eXist-db native XML database (http://exist-db.org).

Features
--------

* **Hierarchical collections**: articles are organized into collections. Each collection may contain one or more articles and an arbitrary number of sub-collections.
* **Blog support**: a collection can be displayed as a weblog feed.
* **Rich wiki markup** with syntax highlighting: our wiki editor allows for fast authoring with a number of useful extensions, e.g. to display a block of source code. The wiki editor supports on-the-fly syntax highlighting of the wiki markup.
* **XML storage**: article metadata is saved using the Atom Syndication Format, which allows for easy exchange with other systems or news readers. The article content is stored separately as an HTML file, so authors can choose to directly edit the HTML using editing tools outside the wiki (e.g. oXygen).
* **XQuery scripting**: embed XQuery code directly into a document and have it executed. Directly query data stored in the database from within an article. Furthermore, all wiki macros are written in XQuery and you can add your own any time.
* **eXist-db Integration**: AtomicWiki ships as a self-contained package which can be deployed into any eXist-db using eXist's application repository. It runs alongside other apps within the same db and ignores any documents which are not part of the wiki.

Current State
-------------
This version of AtomicWiki is a complete rewrite of the older code base. It is usable, but not yet feature-complete. The following features are planned to be implemented next:

+ **Access control**: Right now users can view/edit any resource if they have access rights on the database resource. The editing forms do not provide any means to restrict access. We plan to implement a dedicated security model for the wiki based on ACLs. 
+ **User management**: While users can be added/edited using eXist-db standard tools, there are no forms for this within the wiki.
+ **Commenting**: commenting and annotations will be a major feature of AtomicWiki. We plan to go beyond simple comments attached to an article, allowing users to annotate virtually everything: an article, a piece of text within a page, a relation between two resources, ... 
+ **Resource upload**: Likewise, images or other resources can be uploaded using eXist-db tooling, but not from within the wiki.
+ **Editor improvements**: auto-complete for links, more keyboard shortcuts ...
+ **HTML WYSWIG editor**: since all content is stored as XML/HTML, we could also support editing content with a WYSWIG editor instead of wiki markup. The goal is to allow any type of editor to be plugged in.

Installing jars
---------------
You need to copy two .jar files into your eXist-db installation:

* WikiModelV2.jar
* atomicwiki-0.1.jar

Copy them to

	EXIST_HOME/lib/user

You'll need to restart eXist-db afterwards so it can pick up the jars. This only needs to be done **once**.

Uploading the package
---------------------
The .xar file is an installable package containing the code and initial data for AtomicWiki. You can install this into any eXist 
instance using the application repository manager. In a web browser, open the 
admin web page of your eXist instance and select "Package Repository". Switch to the "Upload" tab and select the .xar
file for upload, then click "Upload Package". After installation has finished, your new version of AtomicWiki (now stored
inside the database) should be accessible at:

     http://localhost:8080/exist/apps/wiki/
   
Building
--------

AtomicWiki is distributed as a .xar package which can be deployed into an existing eXist-db instance through eXist's
application repository.

To build AtomicWiki from scratch,
you should first get eXist-db from SVN and build it (build.sh/build.bat). Next, clone eXide into a directory, e.g.:

     git clone git://github.com/wolfgangmm/AtomicWiki.git AtomicWiki
     cd AtomicWiki
     git submodule update --init --recursive

Edit the file build.properties and change the property exist.dir to point to the root of your eXist installation (eXist-db > 2.0). This is required to compile the Java modules for parsing wiki markup.

Next, call ant on the build.xml file in AtomicWiki:

      ant

You should now find a .xar and a .jar file in the build directory:
     
* build/atomicwiki-0.1.xar
* build/atomicwiki-0.1.jar

Install the jar plus any jar found in java/lib into eXist as described above, then upload the .xar package.
