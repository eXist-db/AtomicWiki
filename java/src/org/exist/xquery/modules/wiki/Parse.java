package org.exist.xquery.modules.wiki;

import org.exist.dom.QName;
import org.exist.memtree.MemTreeBuilder;
import org.exist.memtree.NodeImpl;
import org.exist.xquery.*;
import org.exist.xquery.value.NodeValue;
import org.exist.xquery.value.Sequence;
import org.exist.xquery.value.SequenceType;
import org.exist.xquery.value.Type;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.wikimodel.wem.IWemListener;
import org.wikimodel.wem.IWikiParser;
import org.wikimodel.wem.WikiParserException;
import org.wikimodel.wem.common.CommonWikiParser;

import java.io.StringReader;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by IntelliJ IDEA.
 * User: wolf
 * Date: Oct 10, 2007
 * Time: 4:29:17 PM
 * To change this template use File | Settings | File Templates.
 */
public class Parse extends BasicFunction {

    public final static FunctionSignature signature =
            new FunctionSignature(
                    new QName( "parse", WikiModule.NAMESPACE_URI, WikiModule.PREFIX),
                    "Parse the given text containing wiki markup into XHTML.",
                    new SequenceType[] {
                            new SequenceType( Type.STRING, Cardinality.ZERO_OR_ONE ),
                            new SequenceType( Type.ELEMENT, Cardinality.ZERO_OR_ONE)
                    },
                    new SequenceType( Type.NODE, Cardinality.ZERO_OR_ONE )
            );

    public Parse(XQueryContext context) {
        super(context, signature);
    }

    public Sequence eval(Sequence[] args, Sequence contextSequence) throws XPathException {
        if (args[0].isEmpty())
            return Sequence.EMPTY_SEQUENCE;
		Map params = new HashMap();
		if (!args[1].isEmpty()) {
        	NodeValue paramsNode = (NodeValue) args[1].itemAt(0);
        	parseParameters((Element) paramsNode.getNode(), params);
		}
        StringReader reader = new StringReader(args[0].getStringValue());
        IWikiParser parser = new CommonWikiParser();
        context.pushDocumentContext();
        MemTreeBuilder builder = context.getDocumentBuilder();
        IWemListener listener = new XHTMLListener(builder, params);
        try {
            parser.parse(reader, listener);
            return (NodeImpl) builder.getDocument().getFirstChild();
        } catch (WikiParserException e) {
            LOG.warn(e.getMessage(), e);
            throw new XPathException(this, "An error occurred while parsing wiki text: " + e.getMessage(), e);
        } finally {
            context.popDocumentContext();
        }
    }

    private Map parseParameters(Element root, Map params) {
        Node next = root.getFirstChild();
        while (next != null) {
            if (next.getNodeType() == Node.ELEMENT_NODE && "param".equals(next.getLocalName())) {
                Element param = (Element) next;
                params.put(param.getAttribute("name"), param.getAttribute("value"));
            }
            next = next.getNextSibling();
        }
        return params;
    }
}
