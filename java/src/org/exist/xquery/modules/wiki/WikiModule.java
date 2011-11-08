package org.exist.xquery.modules.wiki;

import org.exist.xquery.AbstractInternalModule;
import org.exist.xquery.FunctionDef;
import java.util.List;
import java.util.Map;

/**
 * Created by IntelliJ IDEA.
 * User: wolf
 * Date: Oct 10, 2007
 * Time: 4:32:36 PM
 * To change this template use File | Settings | File Templates.
 */
public class WikiModule extends AbstractInternalModule {

    public final static String NAMESPACE_URI = "http://exist-db.org/xquery/wiki";
    public final static String PREFIX = "wiki";

    public final static FunctionDef functions[] = {
            new FunctionDef(Parse.signature, Parse.class)
    };

    public WikiModule(Map<String, List<? extends Object>> parameters) {
        super(functions, parameters, true);
    }

    public String getNamespaceURI() {
        return NAMESPACE_URI;
    }

    public String getDefaultPrefix() {
        return PREFIX;
    }

    public String getDescription() {
        return "Functions to parse wiki text into XHTML nodes.";
    }

    public String getReleaseVersion() {
        return "1.4";
    }
}
